#!/usr/bin/env python3

import os
import sys
import iterm2

INWINDOW_LAUNCHER = os.path.realpath(os.path.join(os.path.dirname(__file__), 'inwindow_launcher.py'))

async def main(connection):
    app = await iterm2.async_get_app(connection)

    window = await iterm2.Window.async_create(connection)
    orig_frame = await window.async_get_frame()
    await window.async_set_frame(iterm2.Frame(origin=orig_frame.origin, size=iterm2.Size(1000,600)))
    session = window.current_tab.current_session
    cwd = os.getcwd()
    await session.async_send_text('cd "%s"&& pythonw "%s" %s\n' % (cwd, INWINDOW_LAUNCHER, " ".join(sys.argv[1:])))

iterm2.run_until_complete(main)
