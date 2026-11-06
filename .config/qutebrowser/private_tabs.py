"""Give private windows a red selected tab without changing normal tabs."""

from qutebrowser.config import config
from qutebrowser.mainwindow import tabwidget
from qutebrowser.qt.gui import QColor, QPalette
from qutebrowser.qt.widgets import QStyle, QStyleOptionTab
from qutebrowser.utils import objreg


# Tab colors have no per-window/private setting in qutebrowser 3.7. Override
# only the selected tab's drawing palette, including selected pinned tabs.
# Keep the original class across :config-source reloads instead of nesting.
_base_style = getattr(
    tabwidget.TabBarStyle,
    "_qute_private_base",
    tabwidget.TabBarStyle,
)


class PrivateTabStyle(_base_style):
    _qute_private_base = _base_style

    def drawControl(self, element, option, painter, widget=None):
        if (element in (
                QStyle.ControlElement.CE_TabBarTab,
                QStyle.ControlElement.CE_TabBarTabShape,
                QStyle.ControlElement.CE_TabBarTabLabel,
            )
                and option.state & QStyle.StateFlag.State_Selected
                and isinstance(widget, tabwidget.TabBar)):
            tab = widget._current_tab()
            if tab is not None and tab.is_private:
                option = QStyleOptionTab(option)
                option.palette.setColor(
                    QPalette.ColorRole.Window,
                    QColor(config.cache["colors.messages.error.bg"]),
                )
                option.palette.setColor(
                    QPalette.ColorRole.WindowText,
                    QColor(config.cache["colors.tabs.selected.odd.fg"]),
                )
        return super().drawControl(element, option, painter, widget)


def apply_to_bar(bar):
    previous = bar._our_style
    style = PrivateTabStyle()
    style.setParent(bar)
    bar.setStyle(style)
    bar._our_style = style
    previous.deleteLater()
    bar.update()


# New tab bars construct this style automatically. Refresh existing style
# objects too so their cached stylesheet state picks up the private palette.
tabwidget.TabBarStyle = PrivateTabStyle

# Apply immediately to windows which already exist when the config is sourced.
for window in list(objreg.window_registry):
    try:
        browser = objreg.get("tabbed-browser", scope="window", window=window)
    except KeyError:
        continue
    apply_to_bar(browser.widget.tabBar())
