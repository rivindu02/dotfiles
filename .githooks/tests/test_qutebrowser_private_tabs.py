"""Render real tab bars to check private colors without opening browser pages."""
import os
import faulthandler
from pathlib import Path
import runpy
import tempfile
from types import SimpleNamespace
import unittest
import sys
import traceback

faulthandler.enable()
QT_ERRORS = []


def qt_exception(typ, value, tb):
    QT_ERRORS.append(value)
    traceback.print_exception(typ, value, tb)


sys.excepthook = qt_exception

ROOT = Path(__file__).resolve().parents[2]
SCRATCH = tempfile.TemporaryDirectory(prefix="qute-private-tabs-test-")
for key in ("XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"):
    folder = Path(SCRATCH.name) / key
    folder.mkdir(mode=0o700)
    os.environ[key] = str(folder)
os.environ["QT_QPA_PLATFORM"] = "offscreen"
os.environ["QT_QPA_PLATFORMTHEME"] = ""
os.environ["QT_STYLE_OVERRIDE"] = "Fusion"

from qutebrowser.qt.widgets import QApplication, QTabWidget, QWidget
from qutebrowser.config import config, configcache, configdata, configfiles
from qutebrowser.mainwindow import tabwidget
from qutebrowser.utils import standarddir

APP = QApplication(["qute-private-tabs-test"])
APP.setApplicationName("qute-private-tabs-test")
for key in standarddir._Location:
    standarddir._locations[key] = SCRATCH.name
configdata.init()
config.instance = config.Config(yaml_config=configfiles.YamlConfig())
config.val = config.ConfigContainer(config.instance)
config.key_instance = config.KeyConfig(config.instance)
config.cache = configcache.ConfigCache()
configfiles.read_config_py(ROOT / ".config/qutebrowser/config.py", raising=True, warn_autoconfig=True)
config.instance.set_obj("tabs.pinned.shrink", False)
ORIGINAL = tabwidget.TabBarStyle._qute_private_base
HELPER = ROOT / ".config/qutebrowser/private_tabs.py"


class PrivateTabTests(unittest.TestCase):
    def setUp(self):
        # Construct the styles before patching, matching an existing browser.
        tabwidget.TabBarStyle = ORIGINAL
        self.windows = []
        QT_ERRORS.clear()

    def tearDown(self):
        for window in self.windows:
            window.close()
        APP.processEvents()
        self.assertFalse(QT_ERRORS, QT_ERRORS)

    def window(self, private=False, pinned=False):
        window = QTabWidget()
        window.resize(640, 150)
        bar = tabwidget.TabBar(0, window)
        window.setTabBar(bar)
        # Test the drawing layer with ordinary widgets as browser-tab stand-ins.
        bar._current_tab = window.currentWidget
        bar._tab_pinned = lambda index: pinned
        for title in ("First", "Second"):
            tab = QWidget()
            tab.is_private = private
            tab.data = SimpleNamespace(fullscreen=False)
            window.addTab(tab, title)
        window.show()
        self.windows.append(window)
        APP.processEvents()
        return window, bar

    def color(self, bar, index):
        APP.processEvents()
        rectangle = bar.tabRect(index)
        image = bar.grab().toImage()
        return image.pixelColor(rectangle.right() - 8, rectangle.center().y()).name()

    def test_existing_private_window_becomes_red_while_normal_stays_yellow(self):
        _, normal = self.window()
        _, private = self.window(private=True)
        self.assertEqual(self.color(normal, 0), "#d8a657")
        self.assertEqual(self.color(private, 0), "#d8a657")
        helper = runpy.run_path(str(HELPER))
        helper["apply_to_bar"](normal)
        helper["apply_to_bar"](private)
        self.assertEqual(self.color(normal, 0), "#d8a657")
        self.assertEqual(self.color(private, 0), "#ea6962")

    def test_new_private_windows_and_selected_even_tab_are_red(self):
        runpy.run_path(str(HELPER))
        window, private = self.window(private=True)
        self.assertEqual(self.color(private, 0), "#ea6962")
        window.setCurrentIndex(1)
        self.assertEqual(self.color(private, 1), "#ea6962")
        self.assertEqual(self.color(private, 0), "#282828")

    def test_private_pinned_tabs_are_red_and_normal_pinned_tabs_are_yellow(self):
        runpy.run_path(str(HELPER))
        _, private = self.window(private=True, pinned=True)
        _, normal = self.window(pinned=True)
        self.assertEqual(self.color(private, 0), "#ea6962")
        self.assertEqual(self.color(normal, 0), "#d8a657")

    def test_reloading_helper_does_not_stack_wrappers_or_change_shared_colors(self):
        runpy.run_path(str(HELPER))
        runpy.run_path(str(HELPER))
        self.assertIs(tabwidget.TabBarStyle._qute_private_base, ORIGINAL)
        _, private = self.window(private=True)
        self.assertEqual(self.color(private, 0), "#ea6962")
        self.assertEqual(config.instance.get_obj("colors.tabs.selected.odd.bg"), "#d8a657")


if __name__ == "__main__":
    unittest.main()
