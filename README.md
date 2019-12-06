# iTerm-Split-Automator
Automate the running of commands in split iTerm sessions

## Installation
From the iTerm2 menu, click:
`Scripts->Manage->Import...` then navigate to the launcher.zip file

## Configuration
The configuration yaml file must define two entries:

```yaml
layout: |
    space_separated names of
    split_panes

commands:
    - panes: <regex_matching_pane_names>
      cmd: cmd to run 1

    - panes: <regex_matching_pane_names>
      cmd: cmd to run 2
```

In addition, layouts may define an additional `variables` section, which
contains elements which will later be substituted into commands with pythons
`.format()` method.

Variables that begin with `!password` prompt the user for a password on each run.

Variables that begin with `!prompt` prompt the user for plain-text input on each run.



The following configuration file:
```yaml
variables:
    to_echo: "things to echo"
    my_password: !password enter password
    my_prompt: !prompt enter prompt

layout: |
    row1_A row1_B
    CC D EEE
    last_row

commands:
    # Clear all terminals
    - panes: .*
      cmd: clear

    # Change to test_dir/
    - panes: .*
      cmd: cd test_dir

    - sleep: 1

    # Top row executes `ls`
    - panes: row1_.*
      cmd: ls

    # Write to file from two panes, separated by 1 second
    - panes: (CC)|(EEE)
      cmd: echo "{name} Wrote me to a file" >> test_file
      sleep: 1

    - panes: last_row
      cmd: cat test_file

    - panes: D
      cmd: 'echo {to_echo} : {my_prompt}, {my_password}'

    - sleep: 2

    - panes: .*
      cmd: ls
```
Creates the following terminal:

<img src='sample.gif' width=640 align="middle"/>
