# GitHub CLI credentials

Keep `~/.config/gh` as a real directory with only `config.yml` linked here.
Keep `hosts.yml` outside this repository, mode 600; do not symlink the entire
directory into dotfiles. Git ignore rules do not exclude files from archives.
Exclude credentials from backups, or use encrypted backups.

To replace an existing token, revoke it in GitHub Settings → Developer settings
→ Personal access tokens, then run `gh auth login` and prefer the system
credential store when available. Never paste a token into shell arguments.
