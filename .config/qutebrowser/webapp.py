"""App windows, in a separate qutebrowser instance from normal browsing."""
from pathlib import Path

config.source(str(Path(__file__).resolve().with_name("config.py")))

c.tabs.show = "never"
c.statusbar.show = "never"
c.tabs.tabs_are_windows = True
c.auto_save.session = False
c.session.default_name = None
