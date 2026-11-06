"""Check session transport and picker edge cases with synthetic vault items."""

import json
from pathlib import Path
import runpy
import subprocess
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch


SCRIPT = Path(__file__).resolve().parents[2] / '.config/qutebrowser/userscripts/qute-bitwarden'


class SecurityTests(unittest.TestCase):
    def setUp(self):
        self.script = runpy.run_path(str(SCRIPT))
        self.globals = self.script['main'].__globals__

    def test_keyring_receives_session_on_stdin(self):
        with patch.dict(self.globals, ask_password=Mock(return_value='dummy-session')), \
                patch.object(subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '')), \
                patch.object(subprocess, 'call'), \
                patch.object(subprocess, 'check_output', side_effect=['123\n', 'dummy-session\n']) as output:
            self.assertEqual(self.script['get_session_key'](300, 'prompt'), 'dummy-session')
        call = output.call_args_list[0]
        self.assertEqual(call.args[0], ['keyctl', 'padd', 'user', 'bw_session', '@u'])
        self.assertEqual(call.kwargs['input'], 'dummy-session')

    def test_list_and_totp_use_environment_without_session_argument(self):
        with patch.dict(self.globals, get_session_key=Mock(return_value='dummy-session')), \
                patch.object(subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, b'[]', b'')) as run:
            self.script['pass_']('example.test', 'UTF-8', 300, 'prompt')
            self.script['get_totp_code']('item-id', 'Example', 'UTF-8', 300, 'prompt')
        for call in run.call_args_list:
            self.assertNotIn('--session', call.args[0])
            self.assertNotIn('dummy-session', call.args[0])
            self.assertEqual(call.kwargs['env']['BW_SESSION'], 'dummy-session')

    def test_picker_handles_null_delimiters_controls_and_identical_labels(self):
        items = [
            {'id': 'one', 'name': 'Name | with\nnewlines\x00', 'login': {'username': None, 'password': 'first'}},
            {'id': 'two', 'name': 'Name | with\nnewlines\x00', 'login': {'username': None, 'password': 'second'}},
            {'id': 'three', 'name': 'Other', 'login': {'username': 'a|b', 'password': 'third'}},
        ]
        extracted = SimpleNamespace(fqdn='login.example.test', top_domain_under_public_suffix='example.test',
                                    subdomain='login', domain='example', ipv4='')
        for chosen in range(len(items)):
            def pick(rows, *_):
                self.assertEqual(len(rows), 3)  # merged responses were deduplicated
                self.assertEqual(len(set(rows)), 3)
                self.assertTrue(all(c.isprintable() for row in rows for c in row))
                return rows[chosen].strip()
            args = self.script['argument_parser'].parse_args(['https://login.example.test', '--merge-candidates'])
            fill = Mock()
            with patch.dict(self.globals, pass_=Mock(return_value=json.dumps(items)),
                            dmenu=pick, fill_login=fill), \
                    patch.object(self.globals['tldextract'], 'extract', return_value=extracted):
                self.assertEqual(self.script['main'](args), 0)
            item = items[chosen]
            self.assertEqual(fill.call_args.args[:2], (item['login']['username'], item['login']['password']))


if __name__ == '__main__':
    unittest.main()
