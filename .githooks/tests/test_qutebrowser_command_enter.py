"""Check argument detection and Enter behavior without running browser commands."""
from pathlib import Path
import runpy
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

from qutebrowser.api import cmdutils
from qutebrowser.config import config, configcache, configdata, configfiles
from qutebrowser.utils import objreg, standarddir

SCRATCH = tempfile.TemporaryDirectory(prefix="qute-command-enter-test-")
for location in standarddir._Location:
    standarddir._locations[location] = SCRATCH.name
configdata.init()
config.instance = config.Config(yaml_config=configfiles.YamlConfig())
config.val = config.ConfigContainer(config.instance)
config.cache = configcache.ConfigCache()


@cmdutils.register(name="enter-test-required")
def required(name: str):
    """Test command with a required name."""
    raise AssertionError("Must not execute during argument detection")


@cmdutils.register(name="enter-test-optional")
def optional(name: str = "default"):
    """Test command with an optional name."""
    raise AssertionError("Must not execute during argument detection")


HELPER = runpy.run_path(str(Path(__file__).resolve().parents[2]
                           / ".config/qutebrowser/command_enter.py"))


class CommandEnterTests(unittest.TestCase):
    def test_required_optional_complete_and_invalid_commands(self):
        needs = HELPER["needs_argument"]
        self.assertTrue(needs("enter-test-required"))
        self.assertTrue(needs("enter-test-required "))
        self.assertFalse(needs("enter-test-required 'my project'"))
        self.assertFalse(needs("enter-test-optional"))
        self.assertFalse(needs("unknown-command"))
        self.assertFalse(needs("enter-test-required work --invalid"))
        self.assertFalse(needs("enter-test-required --help"))
        self.assertFalse(needs("enter-test-required ;; enter-test-optional"))

    def invoke(self, text):
        command = Mock()
        command.text.return_value = text
        completion = Mock()
        # Use the real registry: mocking get() hid its command-only restriction
        # and let an invalid completion lookup pass before crashing the browser.
        window = SimpleNamespace(registry=objreg.ObjectRegistry())
        with patch.object(objreg, "window_registry", {0: window}):
            objreg.register("status-command", command, scope="window", window=0)
            objreg.register("completion", completion, scope="window", window=0,
                            command_only=True)
            HELPER["command_enter_next"](0)
        return command, completion

    def test_missing_argument_opens_next_completion(self):
        command, completion = self.invoke(":enter-test-required")
        command.cmd_set_text.assert_called_once_with(":enter-test-required ")
        command.command_accept.assert_not_called()
        completion.completion_item_focus.assert_not_called()

    def test_enter_on_empty_argument_selects_a_completion(self):
        command, completion = self.invoke(":enter-test-required ")
        completion.completion_item_focus.assert_called_once_with("next")
        command.command_accept.assert_not_called()

    def test_complete_commands_and_searches_accept_normally(self):
        for text in (":enter-test-required work", ":enter-test-optional", "/find me"):
            command, completion = self.invoke(text)
            command.command_accept.assert_called_once_with()
            command.cmd_set_text.assert_not_called()
            completion.completion_item_focus.assert_not_called()


if __name__ == "__main__":
    unittest.main()
