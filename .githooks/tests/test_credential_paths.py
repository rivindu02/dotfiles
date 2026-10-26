#!/usr/bin/env python3
"""Check credential guards with fake files, isolated Git, and plugin-free Nvim."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
PRIVATE_TEXT = "A2_SYNTHETIC_CREDENTIAL_FIXTURE"
PROTECTED = [
    ".aws/credentials", ".aws/config", ".aws/sso/cache/session.json",
    ".aws/cli/cache/session.json", ".aws/login/cache/session.json",
    ".config/rclone/rclone.conf", ".config/rclone/rclone.conf.old",
    ".config/rclone/rclone.conf.bak", ".config/restic/password",
    ".config/gh/hosts.yml", ".config/gcalcli/account/oauth.json",
    ".local/share/keyrings/login.keyring", ".local/share/keyrings/private.pub",
    ".claude/.credentials.json", ".codex/auth.json", ".gemini/oauth_creds.json",
    ".npmrc", ".netrc", ".secrets/private.pub", ".openclaude-profile.json",
]
ORDINARY = [
    ".aws/config.example", ".aws/credentials.example",
    ".config/backup/excludes.txt", ".config/restic/excludes.txt",
    ".config/rclone/rclone.conf.example", ".config/gh/config.yml",
    ".claude/settings.json", ".codex/config.toml", ".gemini/settings.json",
    ".npmrc.example", ".netrc.example", "public/id_ed25519.pub",
]


class GitCredentialTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="credential-git-test-")
        self.addCleanup(temporary.cleanup)
        self.repo = Path(temporary.name)
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        self.env.update(GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1")
        self.git("init", "--quiet")
        shutil.copy2(ROOT / ".gitignore", self.repo / ".gitignore")
        (self.repo / ".githooks").mkdir()
        shutil.copy2(ROOT / ".githooks/pre-commit", self.repo / ".githooks/pre-commit")
        self.git("config", "core.hooksPath", ".githooks")

    def git(self, *args):
        return subprocess.run(
            ["git", *args], cwd=self.repo, env=self.env,
            capture_output=True, timeout=30,
        )

    def make_file(self, relative):
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(PRIVATE_TEXT + "\n", encoding="utf-8")

    def commit(self):
        return self.git(
            "-c", "user.name=A2 Fixture", "-c", "user.email=fixture@example.invalid",
            "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "Synthetic fixture",
        )

    def test_private_paths_are_ignored_at_root_and_in_stow_packages(self):
        for prefix in ("", "stow-package/"):
            for relative in PROTECTED:
                path = prefix + relative
                with self.subTest(path=path):
                    self.make_file(path)
                    self.assertEqual(self.git("check-ignore", "--quiet", "--", path).returncode, 0)
                    self.assertNotEqual(self.git("add", "--", path).returncode, 0)
        self.assertEqual(self.git("ls-files").stdout, b"")

    def test_forced_add_is_blocked_at_commit_without_printing_contents(self):
        paths = [prefix + relative for prefix in ("", "stow-package/") for relative in PROTECTED]
        for path in paths:
            self.make_file(path)
        self.assertEqual(self.git("add", "--force", "--", *paths).returncode, 0)
        result = self.commit()
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(PRIVATE_TEXT.encode(), result.stdout + result.stderr)
        for path in paths:
            self.assertIn(f"sensitive file staged: {path}".encode(), result.stderr)
        self.assertNotEqual(self.git("rev-parse", "--verify", "HEAD").returncode, 0)

    def test_ordinary_configs_templates_and_public_keys_can_be_committed(self):
        paths = [prefix + relative for prefix in ("", "stow-package/") for relative in ORDINARY]
        for path in paths:
            with self.subTest(path=path):
                self.make_file(path)
                self.assertEqual(self.git("check-ignore", "--quiet", "--", path).returncode, 1)
        self.assertEqual(self.git("add", "--", *paths).returncode, 0)
        result = self.commit()
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        committed = self.git("ls-tree", "-r", "--name-only", "HEAD").stdout.decode().splitlines()
        self.assertEqual(set(committed), set(paths))


@unittest.skipUnless(shutil.which("nvim"), "Nvim is needed for editor behavior checks")
class NvimCredentialTests(unittest.TestCase):
    def run_editor(self, mode, paths, *, create=True):
        with tempfile.TemporaryDirectory(prefix="credential-nvim-test-") as directory:
            temporary = Path(directory)
            work = temporary / "work"
            work.mkdir()
            for relative in paths:
                path = work / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                if create:
                    path.write_text(PRIVATE_TEXT + "\n", encoding="utf-8")
            fixture_path = temporary / "fixture.json"
            fixture_path.write_text(json.dumps({"mode": mode, "paths": paths}), encoding="utf-8")
            env = os.environ.copy()
            env.update(
                XDG_CONFIG_HOME=str(temporary / "config"),
                XDG_DATA_HOME=str(temporary / "data"),
                XDG_STATE_HOME=str(temporary / "state"),
                XDG_CACHE_HOME=str(temporary / "cache"),
                NVIM_LOG_FILE=str(temporary / "nvim.log"),
                CREDENTIAL_TEST_OPTIONS=str(ROOT / ".config/nvim/lua/core/options.lua"),
                CREDENTIAL_TEST_ROOT=str(temporary),
                CREDENTIAL_TEST_FIXTURE=str(fixture_path),
            )
            init = temporary / "init.lua"
            init.write_text(NVIM_CHECK, encoding="utf-8")
            result = subprocess.run(
                ["nvim", "--headless", "--noplugin", "-i", "NONE", "-u", str(init)],
                cwd=work, env=env, capture_output=True, timeout=30,
            )
            self.assertEqual(result.returncode, 0, (result.stdout + result.stderr).decode())

    def test_existing_credentials_leave_no_undo_swap_or_backup_files(self):
        paths = [prefix + relative for prefix in ("", "stow-package/") for relative in PROTECTED]
        paths += [".ssh/id_ed25519", ".env", "keys/test.pem", "keys/test.key"]
        self.run_editor("private", paths)

    def test_new_credentials_leave_no_undo_swap_or_backup_files(self):
        self.run_editor("private", PROTECTED, create=False)

    def test_ordinary_configs_keep_undo_swap_and_backup_behavior(self):
        self.run_editor("ordinary", ORDINARY)

    def test_saving_an_ordinary_buffer_as_a_credential_is_protected(self):
        self.run_editor("saveas", [".config/restic/password"])

    def test_renaming_an_ordinary_buffer_to_a_credential_is_protected(self):
        self.run_editor("rename", [".aws/credentials"])


NVIM_CHECK = r'''
local function check()
  local root = vim.env.CREDENTIAL_TEST_ROOT
  local fixture = vim.json.decode(table.concat(vim.fn.readfile(vim.env.CREDENTIAL_TEST_FIXTURE), "\n"))
  -- Remove /tmp from backupskip so that the tests exercise our actual patterns.
  vim.o.backupskip = ""
  dofile(vim.env.CREDENTIAL_TEST_OPTIONS)
  vim.o.modeline = false
  vim.o.backup = true
  vim.o.writebackup = true
  vim.o.swapfile = true
  vim.o.undofile = true
  for _, name in ipairs({"undo", "swap", "backup"}) do
    vim.fn.mkdir(root .. "/" .. name, "p")
  end
  vim.opt.undodir = root .. "/undo//"
  vim.opt.directory = root .. "/swap//"
  vim.opt.backupdir = root .. "/backup//"
  local function copies(name)
    return vim.fn.glob(root .. "/" .. name .. "/*", false, true)
  end
  local function private_options(path)
    assert(not vim.bo.undofile, "Undo enabled for " .. path)
    assert(not vim.bo.swapfile, "Swap enabled for " .. path)
    assert(vim.fn.swapname(vim.api.nvim_get_current_buf()) == "", "Swap file remains for " .. path)
  end
  for _, relative in ipairs(fixture.paths) do
    local undo_before, backups_before = #copies("undo"), #copies("backup")
    local path = root .. "/work/" .. relative
    if fixture.mode == "saveas" or fixture.mode == "rename" then
      vim.cmd("edit " .. vim.fn.fnameescape(root .. "/work/scratch.txt"))
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {"synthetic edited value"})
      local command = fixture.mode == "saveas" and "saveas! " or "file "
      vim.cmd(command .. vim.fn.fnameescape(path))
    else
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    end
    local ordinary = fixture.mode == "ordinary"
    if ordinary then
      assert(vim.bo.undofile and vim.bo.swapfile, "Ordinary editing protections changed: " .. relative)
      vim.cmd("preserve")
      assert(vim.fn.swapname(vim.api.nvim_get_current_buf()) ~= "", "Ordinary swap missing")
    else
      private_options(relative)
    end
    for _, text in ipairs({"synthetic edit one", "synthetic edit two"}) do
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {text})
      vim.cmd("write!")
    end
    if not ordinary then private_options(relative) end
    -- Avoid reopening :saveas's ordinary alternate buffer when wiping the last
    -- window: that would legitimately create a new swap for the ordinary file.
    local edited = vim.api.nvim_get_current_buf()
    vim.cmd("enew")
    vim.api.nvim_buf_delete(edited, { force = true })
    if ordinary then
      assert(#copies("undo") > undo_before, "Ordinary undo file missing for " .. relative)
      assert(#copies("backup") > backups_before, "Ordinary backup file missing for " .. relative)
    else
      for _, kind in ipairs({"undo", "swap", "backup"}) do
        assert(#copies(kind) == 0, kind .. " copy left for " .. relative .. ": " .. vim.inspect(copies(kind)))
      end
    end
  end
  -- A fresh ordinary buffer must keep its normal local defaults after secrets.
  vim.cmd("edit " .. vim.fn.fnameescape(root .. "/work/final-normal.txt"))
  assert(vim.bo.undofile and vim.bo.swapfile, "Secret options leaked into another buffer")
end
local ok, err = pcall(check)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
end
vim.cmd("qa!")
'''


if __name__ == "__main__":
    unittest.main(verbosity=2)
