#!/usr/bin/env python3
"""Run the real receiver against fake commands; never access real Taildrop files."""

import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest


RECEIVER = Path(__file__).resolve().parents[2] / ".config/scripts/tailscale-receive.sh"


class ReceiverTests(unittest.TestCase):
    def run_receiver(self, events, *, notifications=0, mkdir_error=False, sleep_exit=0,
                     initial_files=None):
        with tempfile.TemporaryDirectory(prefix="taildrop-receiver-test-") as directory:
            temporary = Path(directory)
            commands = temporary / "bin"
            commands.mkdir()
            stub = commands / "fake-command"
            stub.write_text(f"#!{sys.executable}\n" + FAKE_COMMAND, encoding="utf-8")
            stub.chmod(0o755)
            for name in ("mkdir", "find", "tailscale", "sleep", "notify-send"):
                (commands / name).symlink_to(stub)
            (temporary / "fixture.json").write_text(json.dumps({
                "events": events, "mkdir_error": mkdir_error, "sleep_exit": sleep_exit,
            }), encoding="utf-8")
            (temporary / "state.json").write_text(json.dumps({
                "next": 0, "files": initial_files or [],
            }), encoding="utf-8")
            env = os.environ.copy()
            env.update(PATH=str(commands) + os.pathsep + env["PATH"],
                       TAILDROP_TEST_ROOT=str(temporary))
            # HOME stays unchanged. Fake mkdir/find/tailscale intercept every
            # access to the receiver's normal directory without touching it.
            with (temporary / "stdout").open("w+") as stdout, (temporary / "stderr").open("w+") as stderr:
                process = subprocess.Popen(
                    [shutil.which("bash"), str(RECEIVER)], env=env, cwd=temporary,
                    stdout=stdout, stderr=stderr, start_new_session=True,
                )
                ready = False
                try:
                    deadline = time.monotonic() + 8
                    while time.monotonic() < deadline:
                        log_path = temporary / "calls.jsonl"
                        calls = [json.loads(line) for line in log_path.read_text().splitlines()] if log_path.exists() else []
                        seen_notifications = sum(call["command"] == "notify-send" for call in calls)
                        if (temporary / "finished").exists() and seen_notifications >= notifications:
                            ready = True
                            break
                        if process.poll() is not None:
                            ready = True
                            break
                        time.sleep(0.01)
                    exit_code = process.poll()
                finally:
                    # Include asynchronous fake notification children in cleanup.
                    try:
                        os.killpg(process.pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                    process.wait(timeout=3)
                stdout.seek(0)
                stderr.seek(0)
                output, errors = stdout.read(), stderr.read()
                self.assertTrue(ready, "Receiver failed to reach the fixture endpoint: " + errors)
            calls = [json.loads(line) for line in (temporary / "calls.jsonl").read_text().splitlines()]
            return calls, output, errors, exit_code

    def test_failures_use_capped_backoff_and_keep_command_errors(self):
        calls, _, errors, _ = self.run_receiver([{"status": status} for status in range(1, 8)])
        self.assertEqual([call["args"] for call in calls if call["command"] == "sleep"],
                         [["5"], ["10"], ["20"], ["40"], ["60"], ["60"], ["60"]])
        self.assertEqual(errors.count("synthetic tailscale error"), 7)
        self.assertEqual(errors.count("receive failed (exit"), 7)
        self.assertIn("exit 7); retrying in 60 seconds", errors)
        self.assertNotIn("receive recovered", errors)

    def test_success_resets_backoff_and_logs_recovery_once(self):
        calls, _, errors, _ = self.run_receiver([
            {"status": 1}, {"status": 2}, {"status": 0},
            {"status": 3}, {"status": 0}, {"status": 0},
        ])
        self.assertEqual([call["args"] for call in calls if call["command"] == "sleep"],
                         [["5"], ["10"], ["5"]])
        self.assertEqual(errors.count("receive recovered"), 2)

    def test_single_file_keeps_the_clickable_notification_and_rename_option(self):
        calls, _, errors, _ = self.run_receiver(
            [{"status": 0, "files": ["2000 report (1).pdf"]}], notifications=1,
            initial_files=["1000 report.pdf"],
        )
        notices = [call["args"] for call in calls if call["command"] == "notify-send"]
        self.assertEqual(len(notices), 1)
        self.assertIn("Received: report (1).pdf", notices[0])
        self.assertIn("string:filepath:" + str(Path.home() / "tailscale/report (1).pdf"), notices[0])
        self.assertIn("default=Show in yazi", notices[0])
        receives = [call["args"] for call in calls if call["command"] == "tailscale"]
        for args in receives:
            self.assertEqual(args, ["file", "get", "--wait", "--conflict=rename", str(Path.home() / "tailscale")])
        self.assertNotIn("receive recovered", errors)

    def test_multiple_files_keep_the_folder_notification(self):
        calls, _, _, _ = self.run_receiver(
            [{"status": 0, "files": ["2000 one.txt", "2001 two words.png"]}], notifications=1,
        )
        notices = [call["args"] for call in calls if call["command"] == "notify-send"]
        self.assertEqual(len(notices), 1)
        self.assertIn("Received 2 files", notices[0])
        self.assertIn("string:filepath:" + str(Path.home() / "tailscale"), notices[0])
        self.assertIn("default=Open folder", notices[0])

    def test_success_without_new_files_does_not_notify_or_delay(self):
        calls, _, errors, _ = self.run_receiver([{"status": 0}])
        self.assertFalse(any(call["command"] in ("notify-send", "sleep") for call in calls))
        self.assertEqual(errors, "")

    def test_directory_setup_failure_exits_without_trying_to_receive(self):
        calls, _, errors, exit_code = self.run_receiver([], mkdir_error=True)
        self.assertEqual(exit_code, 1)
        self.assertIn("cannot prepare the download directory", errors)
        self.assertFalse(any(call["command"] == "tailscale" for call in calls))

    def test_failed_retry_sleep_exits_instead_of_spinning(self):
        calls, _, _, exit_code = self.run_receiver([{"status": 1}], sleep_exit=9)
        self.assertEqual(exit_code, 9)
        self.assertEqual(sum(call["command"] == "tailscale" for call in calls), 1)
        self.assertEqual(sum(call["command"] == "sleep" for call in calls), 1)


FAKE_COMMAND = r'''
import json
import os
from pathlib import Path
import signal
import sys

root = Path(os.environ["TAILDROP_TEST_ROOT"])
fixture = json.loads((root / "fixture.json").read_text())
command = Path(sys.argv[0]).name
call = json.dumps({"command": command, "args": sys.argv[1:]}) + "\n"
with (root / "calls.jsonl").open("a") as log:
    log.write(call)
if command == "mkdir":
    if fixture["mkdir_error"]:
        print("synthetic mkdir error", file=sys.stderr)
        sys.exit(1)
elif command == "find":
    state = json.loads((root / "state.json").read_text())
    for entry in state["files"]:
        print(entry)
elif command == "tailscale":
    state = json.loads((root / "state.json").read_text())
    if state["next"] >= len(fixture["events"]):
        (root / "finished").touch()
        signal.pause()
        sys.exit(0)
    event = fixture["events"][state["next"]]
    state["next"] += 1
    if event["status"] == 0:
        state["files"].extend(event.get("files", []))
    (root / "state.json").write_text(json.dumps(state))
    if event["status"]:
        print("synthetic tailscale error", file=sys.stderr)
    sys.exit(event["status"])
elif command == "sleep":
    sys.exit(fixture["sleep_exit"])
elif command != "notify-send":
    raise AssertionError("Unexpected fake command")
'''


if __name__ == "__main__":
    unittest.main(verbosity=2)
