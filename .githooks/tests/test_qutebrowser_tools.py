"""Check URL encoding, download selection and local reader extraction."""

import importlib.machinery
import importlib.util
import os
from pathlib import Path
import shlex
import stat
import tempfile
import unittest
from unittest.mock import Mock, patch
from urllib.parse import parse_qs, urlsplit, unquote

from qutebrowser.browser import commands, hints
from qutebrowser.commands.parser import CommandParser
from qutebrowser.config import config, configcache, configdata, configfiles
from qutebrowser.utils import standarddir


# Exercise qutebrowser's real parser. :open deliberately preserves quotes,
# unlike shlex.split; using a shell parser hid the translation regression.
CONFIG_SCRATCH = tempfile.TemporaryDirectory(prefix="qute-tools-config-")
for location in standarddir._Location:
    standarddir._locations[location] = CONFIG_SCRATCH.name
configdata.init()
config.instance = config.Config(yaml_config=configfiles.YamlConfig())
config.val = config.ConfigContainer(config.instance)
config.key_instance = config.KeyConfig(config.instance)
config.cache = configcache.ConfigCache()


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / ".config/qutebrowser/userscripts/browser-tools"
loader = importlib.machinery.SourceFileLoader("qutebrowser_tools", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
tools = importlib.util.module_from_spec(spec)
loader.exec_module(tools)


class BrowserToolsTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="qute-tools-test-")
        self.addCleanup(self.scratch.cleanup)
        self.root = Path(self.scratch.name)
        self.fifo = self.root / "commands"
        self.fifo.touch()
        self.env = patch.dict(os.environ, {
            "QUTE_FIFO": str(self.fifo),
            "QUTE_URL": "https://example.test/article?a=1&b=a%20b#part",
            "QUTE_SELECTED_TEXT": "",
        })
        self.env.start()
        self.addCleanup(self.env.stop)

    def command(self):
        lines = self.fifo.read_text().splitlines()
        self.assertEqual(len(lines), 1, "Userscript must emit one command")
        parsed = CommandParser().parse_all(lines[0])
        self.assertEqual(len(parsed), 1, "Userscript must not inject a command chain")
        result = parsed[0]
        result.cmd.parser.parse_args(result.args)
        return [result.cmd.name, *result.args]

    def test_brave_uses_separate_url_argument_and_requests_a_new_window(self):
        url = "https://example.test/search?q=a%20b&x=';;quit#fragment"
        with patch.dict(os.environ, {"QUTE_URL": url}), \
                patch.object(tools.shutil, "which", return_value="/usr/bin/brave"), \
                patch.object(tools.subprocess, "Popen") as process:
            process.return_value.wait.return_value = 0
            tools.open_brave()
            self.assertEqual(process.call_args.args[0], ["/usr/bin/brave", "--new-window", "--", url])
            self.assertTrue(process.call_args.kwargs["start_new_session"])

    def test_brave_reports_startup_error_and_handles_a_running_browser(self):
        def failed(*args, **kwargs):
            kwargs["stderr"].write(b"Wayland connection failed")
            return Mock(wait=Mock(return_value=1))
        with patch.object(tools.shutil, "which", return_value="/usr/bin/brave"), \
                patch.object(tools.subprocess, "Popen", side_effect=failed):
            with self.assertRaisesRegex(tools.ToolError, "Wayland connection failed"):
                tools.open_brave()
        with patch.object(tools.shutil, "which", return_value="/usr/bin/brave"), \
                patch.object(tools.subprocess, "Popen") as process:
            process.return_value.wait.side_effect = tools.subprocess.TimeoutExpired("brave", 2)
            tools.open_brave()
            process.return_value.terminate.assert_not_called()

    def test_brave_rejects_internal_pages_and_unwraps_pdf_source(self):
        with patch.object(tools.shutil, "which", return_value="/usr/bin/brave"), \
                patch.object(tools.subprocess, "Popen") as process:
            with patch.dict(os.environ, {"QUTE_URL": "qute://settings/"}):
                with self.assertRaises(tools.ToolError):
                    tools.open_brave()
            process.assert_not_called()
            with patch.dict(os.environ, {"QUTE_URL": "qute://pdfjs/web/viewer.html?source=https%3A%2F%2Fexample.test%2Fa.pdf"}):
                process.return_value.wait.return_value = 0
                tools.open_brave()
            self.assertEqual(process.call_args.args[0][-1], "https://example.test/a.pdf")

    def test_page_translation_keeps_complete_source_url(self):
        tools.translate("si")
        command = self.command()
        self.assertEqual(command[:2], ["open", "-t"])
        query = parse_qs(urlsplit(command[2]).query)
        self.assertEqual(query["u"], [os.environ["QUTE_URL"]])
        self.assertEqual(query["tl"], ["si"])
        self.assertEqual(urlsplit(command[2]).scheme, "https")
        self.assertEqual(urlsplit(command[2]).hostname, "translate.google.com")

    def test_selection_cannot_turn_into_another_browser_command(self):
        selected = "සිංහල தமிழ் & query='x'\n;; open https://evil.test/#fragment"
        with patch.dict(os.environ, {"QUTE_SELECTED_TEXT": selected}):
            tools.translate(selection=True)
        query = parse_qs(urlsplit(self.command()[2]).query)
        self.assertEqual(query["text"], [selected])
        self.assertEqual(urlsplit(self.command()[2]).hostname, "translate.google.com")

    def test_open_rejects_unencoded_command_delimiters(self):
        for url in ["https://example.test/?q=a b", "https://example.test/;;quit", "https://example.test/\nquit"]:
            with self.subTest(url=url), self.assertRaises(tools.ToolError):
                tools.emit("open", "-t", url)
        self.assertEqual(self.fifo.read_text(), "")

    def test_mpv_link_hint_passes_the_chosen_url_to_spawn(self):
        # Invoke the same hint action used by ,M, without opening a player.
        from qutebrowser.qt.core import QUrl
        from qutebrowser.browser.hints import HintActions, HintContext
        binding = "hint links spawn --detach mpv -- {hint-url}"
        parsed = CommandParser().parse(binding)
        args = parsed.cmd.parser.parse_args(parsed.args)
        context = HintContext(
            tab=None, target=hints.Target.spawn, rapid=False, hint_mode="letter",
            add_history=False, first=False, baseurl=QUrl("https://www.youtube.com/"),
            args=args.args, group="links",
        )
        url = "https://www.youtube.com/watch?v=chosen-video&list=playlist"
        with patch("qutebrowser.browser.hints.runners.CommandRunner") as runner:
            HintActions(0).spawn(QUrl(url), context)
        spawned = runner.return_value.run_safely.call_args.args[0]
        parsed_spawn = CommandParser().parse(spawned)
        options = parsed_spawn.cmd.parser.parse_args(parsed_spawn.args)
        self.assertTrue(options.detach)
        self.assertEqual(shlex.split(options.cmdline), ["mpv", "--", url])

    def test_empty_selection_and_local_page_are_not_sent(self):
        with self.assertRaises(tools.ToolError):
            tools.translate(selection=True)
        with patch.dict(os.environ, {"QUTE_URL": "file:///private/article.html"}):
            with self.assertRaises(tools.ToolError):
                tools.translate()
        self.assertEqual(self.fifo.read_text(), "")

    def test_download_picker_uses_original_filename_and_mtime_order(self):
        older = self.root / "old.txt"
        older.write_text("old")
        os.utime(older, (100, 100))
        newest = self.root / "new 'quoted' & spaced\nfilename.txt"
        newest.write_text("new")
        os.utime(newest, (200, 200))
        os.utime(self.fifo, (50, 50))
        result = tools.subprocess.CompletedProcess("rofi", 0, "0\n", "")
        with patch.object(tools.shutil, "which", return_value="/usr/bin/tool"), \
                patch.object(tools.subprocess, "run", return_value=result) as picker, \
                patch.object(tools.subprocess, "Popen") as opener:
            tools.downloads(str(self.root))
        self.assertIn("new 'quoted' & spaced\\nfilename.txt", picker.call_args.kwargs["input"].splitlines()[0])
        self.assertEqual(opener.call_args.args[0], ["xdg-open", str(newest)])

    def test_canceling_download_picker_does_not_open_anything(self):
        result = tools.subprocess.CompletedProcess("rofi", 1, "", "")
        with patch.object(tools.shutil, "which", return_value="/usr/bin/tool"), \
                patch.object(tools.subprocess, "run", return_value=result), \
                patch.object(tools.subprocess, "Popen") as opener:
            tools.downloads(str(self.root))
        opener.assert_not_called()
        self.assertEqual(self.fifo.read_text(), "")

    def test_reader_keeps_article_and_links_without_active_markup(self):
        paragraph = "This article explains a useful topic in enough detail for an article reader. " * 12
        source = f'''<html><head><title>Sample &amp; safe</title></head>
        <body><nav>Menu</nav><article><h1>Sample &amp; safe</h1>
        <p>{paragraph}<a href="../reference">Reference</a></p>
        <img src="/picture.png" onerror="alert(1)">
        <script>alert('reader script')</script>
        <iframe src="https://evil.test/"></iframe>
        <form action="https://evil.test/"><input name="private"></form>
        <a href="javascript:alert(1)">Unsafe link</a></article></body></html>'''
        content = tools.reader_document(source, "https://example.test/articles/topic")
        self.assertIn(paragraph, content)
        self.assertIn("https://example.test/reference", content)
        self.assertIn("https://example.test/picture.png", content)
        self.assertIn("Sample &amp; safe", content)
        for active in ["<script", "<iframe", "<form", "onerror=", "javascript:"]:
            self.assertNotIn(active, content.lower())
        self.assertIn("default-src 'none'", content)

    def test_reader_tabs_get_distinct_private_runtime_files(self):
        source = self.root / "source.html"
        source.write_text("<p>" + "This is a complete article paragraph, with meaningful sentences. " * 20 + "</p>")
        with patch.dict(os.environ, {"QUTE_HTML": str(source)}), \
                patch.object(tools.subprocess, "Popen") as cleanup:
            tools.reader()
            first = Path(unquote(urlsplit(self.command()[2]).path))
            tools.reader()
            second = Path(unquote(urlsplit(self.command()[2]).path))
        self.assertEqual(cleanup.call_count, 2)
        self.assertNotEqual(first, second)
        for call, path in zip(cleanup.call_args_list, [first, second]):
            self.assertEqual(path.parent, self.root)
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
            self.assertIn("Open original page", path.read_text())
            args = call.args[0]
            self.assertEqual(args[-1], str(path))
            self.assertTrue(call.kwargs['start_new_session'])
            # Execute the real cleanup body with only the delay mocked.
            with patch('sys.argv', ['-c', str(path)]), patch('time.sleep') as delay:
                exec(args[2])
            delay.assert_called_once_with(300)
            self.assertFalse(path.exists())


if __name__ == "__main__":
    unittest.main()
