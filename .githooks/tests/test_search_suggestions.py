#!/usr/bin/env python3
"""Exercise provider parsing and the native mode with an isolated fake Rofi view."""
import importlib.util
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / ".config/rofi/scripts"
spec = importlib.util.spec_from_file_location("suggestions", SCRIPTS / "search-suggestions.py")
provider = importlib.util.module_from_spec(spec)
spec.loader.exec_module(provider)


class ProviderTests(unittest.TestCase):
    def fetch(self, payload):
        with patch.object(provider, "urlopen") as request:
            request.return_value.__enter__.return_value.read.return_value = json.dumps(payload).encode()
            result = provider.suggestions("linux & café")
            self.assertIn("q=linux+%26+caf%C3%A9", request.call_args.args[0].full_url)
            self.assertEqual(request.call_args.kwargs["timeout"], 2)
            return result

    def test_sanitizes_deduplicates_and_limits(self):
        result = self.fetch(["linux & café", ["linux & café", " a\nb ", "a b", None,
                                              "x" * 513, *map(str, range(10))]])
        self.assertEqual(result, ["a b", "0", "1", "2", "3", "4"])

    def test_unexpected_payloads(self):
        for payload in ({"error": "blocked"}, [], ["query", {}], ["query", [None, 123]]):
            self.assertEqual(self.fetch(payload), [])

    def test_youtube_uses_video_suggestions(self):
        with patch.object(provider, "urlopen") as request:
            request.return_value.__enter__.return_value.read.return_value = b'["linux", ["linux sinhala", "linux mint"], {}]'
            self.assertEqual(provider.suggestions("linux", "youtube"), ["linux sinhala", "linux mint"])
            url = request.call_args.args[0].full_url
            self.assertTrue(url.startswith("https://suggestqueries.google.com/"))
            self.assertIn("ds=yt", url)
            self.assertIn("client=firefox", url)

    def test_unknown_provider_makes_no_request(self):
        with patch.object(provider, "urlopen") as request:
            self.assertEqual(provider.suggestions("linux", "unknown"), [])
            request.assert_not_called()


class PlatformWindowTests(unittest.TestCase):
    def test_each_platform_selects_its_source_and_style(self):
        with tempfile.TemporaryDirectory(prefix="rofi-platform-test-") as temp:
            directory = Path(temp)
            rofi = directory / "rofi"
            rofi.write_text(
                '#!/usr/bin/python3\nimport json, os, sys\n'
                'print(json.dumps({"args": sys.argv[1:], '
                '"platform": os.environ["ROFI_SEARCH_PLATFORM"], '
                '"provider": os.environ["ROFI_SEARCH_PROVIDER"]}))\n'
            )
            rofi.chmod(0o755)
            env = dict(os.environ, PATH=f"{temp}:{os.environ['PATH']}", XDG_CACHE_HOME=f"{temp}/cache")
            for key, label, color, source in (
                ("duckduckgo", "DuckDuckGo", "#DE5833", "duckduckgo"),
                ("chatgpt", "ChatGPT", "#10A37F", "duckduckgo"),
                ("claude", "Claude", "#D79921", "duckduckgo"),
                ("youtube", "YouTube", "#FB4934", "youtube"),
            ):
                with self.subTest(platform=key):
                    run = subprocess.run(["bash", str(SCRIPTS / "query-suggestions.sh"), key],
                                         env=env, capture_output=True, text=True, timeout=15, check=True)
                    result = json.loads(run.stdout)
                    self.assertEqual(result["platform"], label)
                    self.assertEqual(result["provider"], source)
                    self.assertIn("search-suggestions", result["args"])
                    style = result["args"][result["args"].index("-theme-str") + 1]
                    self.assertIn(color, style)
                    self.assertIn(label, style)


HARNESS = r'''
#include "SOURCE"
static const char *text = "";
static int redraws = 0;
void *mode_get_private_data(const Mode *m) { return m->private_data; }
void mode_set_private_data(Mode *m, void *p) { m->private_data = p; }
RofiViewState *rofi_view_get_active(void) { return (RofiViewState *)&mode; }
const char *rofi_view_get_user_input(const RofiViewState *v) { (void)v; return text; }
void rofi_view_reload(void) { redraws++; }
void rofi_view_set_selected_line(RofiViewState *v, unsigned int i) { (void)v; (void)i; }
static void pump(void) {
    gint64 end = g_get_monotonic_time() + 250000;
    while (g_get_monotonic_time() < end) {
        while (g_main_context_iteration(NULL, FALSE)) {}
        g_usleep(1000);
    }
}
int main(int argc, char **argv) {
    g_assert_cmpint(argc, ==, 3);
    g_setenv("ROFI_SEARCH_HELPER", argv[1], TRUE);
    init(&mode);
    State *s = mode_get_private_data(&mode);
    g_assert_cmpuint(count(&mode), ==, 0);
    text = "linux";
    tick(&mode);
    g_assert_true(s->pending);
    g_assert_null(s->process);
    s->changed -= 400000;
    tick(&mode);
    g_assert_nonnull(s->process);
    if (strcmp(argv[2], "timeout") == 0) {
        s->started -= 3000000;
        tick(&mode);
        g_assert_null(s->process);
        pump();
        g_assert_cmpuint(count(&mode), ==, 0);
        char *input = (char *)text;
        result(&mode, MENU_OK, &input, 0);
    } else if (strcmp(argv[2], "clear") == 0) {
        text = "";
        tick(&mode);
        g_assert_null(s->process);
        pump();
        g_assert_cmpuint(count(&mode), ==, 0);
        g_assert_false(s->pending);
    } else if (strcmp(argv[2], "destroy") == 0) {
        destroy(&mode);
        pump(); /* Pending callback must not access the destroyed state. */
        return 0;
    } else {
        pump();
        g_assert_cmpuint(count(&mode), ==, 2);
        g_assert_cmpstr(g_ptr_array_index(s->rows, 0), ==, "linux mint");
        char *input = (char *)text;
        if (strcmp(argv[2], "stale") == 0) input = "new query & café";
        int flags = MENU_OK;
        if (strcmp(argv[2], "exact") == 0) flags |= MENU_CUSTOM_INPUT;
        if (strcmp(argv[2], "cancel") == 0) flags = MENU_CANCEL;
        result(&mode, flags, &input, 0);
    }
    destroy(&mode);
    g_assert_cmpint(redraws, >, 0);
    return 0;
}
'''


class NativeModeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="rofi-search-test-")
        cls.addClassCleanup(cls.temp.cleanup)
        directory = Path(cls.temp.name)
        source = directory / "harness.c"
        source.write_text(HARNESS.replace("SOURCE", str(SCRIPTS / "search-suggestions.c")))
        cls.helper = directory / "helper.py"
        cls.helper.write_text('import time\ntime.sleep(0.06)\nprint("linux mint\\nlinux kernel")\n')
        cls.binary = directory / "harness"
        flags = shlex.split(subprocess.check_output(
            ["pkg-config", "--cflags", "--libs", "rofi", "gio-2.0"], text=True))
        subprocess.run(["cc", "-std=c11", "-Wall", "-Wextra", "-Werror",
                        str(source), "-o", str(cls.binary), *flags], check=True)

    def run_mode(self, scenario):
        run = subprocess.run([str(self.binary), str(self.helper), scenario],
                             text=True, capture_output=True, timeout=5)
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertEqual(run.stderr, "")
        return run.stdout

    def test_select_suggestion(self):
        self.assertEqual(self.run_mode("select"), "linux mint\n")

    def test_exact_query(self):
        self.assertEqual(self.run_mode("exact"), "linux\n")

    def test_submit_before_poll_never_uses_old_suggestion(self):
        self.assertEqual(self.run_mode("stale"), "new query & café\n")

    def test_cancel(self):
        self.assertEqual(self.run_mode("cancel"), "")

    def test_clear_cancels_request(self):
        self.assertEqual(self.run_mode("clear"), "")

    def test_destroy_during_request(self):
        self.assertEqual(self.run_mode("destroy"), "")

    def test_hard_timeout_keeps_query_searchable(self):
        self.assertEqual(self.run_mode("timeout"), "linux\n")


if __name__ == "__main__":
    unittest.main()
