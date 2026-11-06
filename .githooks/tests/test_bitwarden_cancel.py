#!/usr/bin/env python3
"""Check prompt cancellation without accessing a vault or opening Rofi."""

from pathlib import Path
import runpy
import subprocess
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[2] / '.config/qutebrowser/userscripts/qute-bitwarden'


class CancelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.script = runpy.run_path(str(SCRIPT))

    def test_cancelled_or_empty_password_exits_without_unlocking(self):
        for code, output in ((1, ''), (1, 'ignored'), (0, ''), (0, '\n')):
            with self.subTest(code=code, output=output), patch.object(
                subprocess, 'run', return_value=subprocess.CompletedProcess([], code, output)
            ), patch.object(subprocess, 'check_output') as unlock:
                with self.assertRaises(SystemExit) as result:
                    self.script['ask_password']('rofi -dmenu')
                self.assertEqual(result.exception.code, 0)
                unlock.assert_not_called()

    def test_cancelled_picker_ignores_output(self):
        with patch.object(subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, b'login')):
            self.assertEqual(self.script['dmenu'](['login'], 'rofi -dmenu', 'UTF-8'), '')

    def test_prompt_failures_still_raise(self):
        for name, args in (
            ('ask_password', ('rofi -dmenu',)),
            ('dmenu', (['login'], 'rofi -dmenu', 'UTF-8')),
        ):
            with self.subTest(prompt=name), patch.object(
                subprocess, 'run', return_value=subprocess.CompletedProcess([], 2, '')
            ):
                with self.assertRaises(RuntimeError):
                    self.script[name](*args)


if __name__ == '__main__':
    unittest.main()
