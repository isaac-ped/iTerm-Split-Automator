#!/usr/bin/env python3
import yaml
import json
import os
import time
import re
import sys
import getpass
import iterm2

RECENT_STORE = os.path.join(os.path.dirname(__file__), 'recents.json')

class InputObj(yaml.YAMLObject):
    def __repr__(self):
        return self.value

    @classmethod
    def from_yaml(cls, loader, node):
        return cls(node.value)

    @classmethod
    def to_yaml(cls, dumper, data):
        return dumper.represent_scalar(cls.yaml_tag, data.value)

    @classmethod
    def register(cls):
        yaml.SafeLoader.add_constructor(cls.yaml_tag, cls.from_yaml)
        yaml.SafeDumper.add_multi_representer(cls, cls.to_yaml)

class PromptObj(InputObj):
    yaml_tag = u'!prompt'

    def __init__(self, prompt):
        self.value = input("%s: " % prompt)

class PasswordObj(InputObj):
    yaml_tag = u'!password'

    def __init__(self, prompt):
        self.value = getpass.getpass("%s: " % prompt)

PromptObj.register()
PasswordObj.register()

def cli_dialog():
    os.system('clear')
    if os.path.exists(RECENT_STORE):
        recents = json.load(open(RECENT_STORE))
    else:
        recents = []

    for i, recent in enumerate(recents[:10], 1):
        print("%d) %s" % (i, recent))

    while True:
        print("")
        id = input("Enter number or filename: " if len(recents) else "Enter filename: ")
        try:
            id = int(id)
            return recents[id - 1]
        except ValueError as e:
            if os.path.exists(os.path.expanduser(id.strip())):
                return os.path.expanduser(id.strip())

async def createRow(orig, names):
    splits = {}
    next = orig
    splits[names[0]] = orig
    await orig.async_set_name(names[0])
    for name in names[1:]:
        next = await next.async_split_pane(vertical=True)
        splits[name] = next
        await next.async_set_name(name)
    return splits

async def create_layout(connection, cfg):
    app = await iterm2.async_get_app(connection)

    cfg_layout = cfg['layout']

    split_names = []
    for line in cfg_layout.split('\n'):
        row = []
        for elem in line.split():
            row.append(elem)
        if len(row):
            split_names.append(row)

    window = app.current_window

    if 'size' in cfg:
        orig_frame = await window.async_get_frame()
        await window.async_set_frame(iterm2.Frame(origin=orig_frame.origin, size=iterm2.Size(*cfg['size'])))

    original = window.current_tab.current_session
    next = original
    rows = []
    for row in split_names:
        next = await next.async_split_pane(vertical=False)
        rows.append(next)

    splits = {}
    for row, names in zip(rows, split_names):
        splits.update(await createRow(row, names))

    for cmd in cfg['commands']:
        if 'panes' not in cmd and 'sleep' in cmd:
            time.sleep(float(cmd['sleep']))
            continue

        if not isinstance(cmd['panes'], list):
            panes = [cmd['panes']]
        else:
            panes = cmd['panes']

        for split_name, split in splits.items():
            for pane in panes:
                if re.fullmatch(pane, split_name):
                    pane_cmd = cmd['cmd'].format(name=split_name, **cfg.get('variables', {}))
                    await split.async_send_text(pane_cmd + '\n')
                    time.sleep(float(cmd.get('sleep', 0)))

    time.sleep(1)
    await original.async_close(force = True)

async def main(connection):
    if len(sys.argv) == 1:
        filename = cli_dialog()
    else:
        filename = sys.argv[1]

    print("Loading from %s" % filename)
    cfg = yaml.load(open(filename), Loader=yaml.SafeLoader)

    if os.path.exists(RECENT_STORE):
        recents = json.load(open(RECENT_STORE))
    else:
        recents = []

    filename = os.path.realpath(filename)

    if filename in recents:
        del recents[recents.index(filename)]
    recents.insert(0, filename)

    json.dump(recents, open(RECENT_STORE, 'w'))

    await create_layout(connection, cfg)

iterm2.run_until_complete(main)
