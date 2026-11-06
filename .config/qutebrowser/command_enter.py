"""Let Enter advance to required arguments before executing a command."""

from qutebrowser.api import cmdutils
from qutebrowser.commands import argparser, cmdexc, parser
from qutebrowser.misc import objects
from qutebrowser.utils import objreg


def needs_argument(text):
    """Check one command without executing it or expanding URL variables."""
    try:
        commands = parser.CommandParser().parse_all(text)
    except cmdexc.Error:
        return False
    if len(commands) != 1:
        return False
    command = commands[0]
    # argparse's help action opens a page: leave help to normal execution.
    if any(arg in ("-h", "--help") for arg in command.args):
        return False
    try:
        command.cmd.parser.parse_args(command.args)
    except argparser.ArgumentParserError as error:
        message = str(error).lower()
        return (message.startswith("the following arguments are required:")
                or "expected one argument" in message
                or "expected at least one argument" in message)
    except argparser.ArgumentParserExit:
        return False
    return False


objects.commands.pop("command-enter-next", None)


@cmdutils.register(name="command-enter-next")
@cmdutils.argument("win_id", value=cmdutils.Value.win_id)
def command_enter_next(win_id: int):
    """Advance to missing command arguments, otherwise accept normally."""
    command = objreg.get("status-command", scope="window", window=win_id)
    text = command.text()
    if text.startswith(":") and needs_argument(text[1:]):
        if not text.endswith(" "):
            command.cmd_set_text(text + " ")
        else:
            # Completion is registered for commands only. This handler is a
            # command too, so use the registry's command access explicitly.
            completion = objreg.get("completion", scope="window", window=win_id,
                                    from_command=True)
            completion.completion_item_focus("next")
        return
    command.command_accept()
