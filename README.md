# iTerm-Split-Automator
Automate the running of commands in split iTerm sessions

## Installation
Place `Launch.scpt` in the directory `~/Library/Application Support/iTerm/Scripts` (create it if it doesn't exist).
Restart iTerm, and the script will now show up under `Scripts` in the toolbar.

## Configuration
Configuration files are split into three sections:
```
LAYOUT
--
VARIABLES
--
COMMANDS
```

The following configuration file:
```cfg
term_A B
C D terminal_E
F
--
THINGS
&this will be prompted for
$this will be prompted for with hidden characters
--
* clear # Clear all terminals
term_A ls # Execute 'ls' in terminal (1,1)
B echo "Write me to a file" > test_file # Execute in terminal (1,2)
!1 # Pause for 1 second
*.25 cat test_file # Execute in all terminals with .25 seconds between execution
!2 # Pause for 2 seoncds
F echo $1 # Echo the first variable
D echo $2 # Echo the variable that was prompted for
terminal_E echo $3 # Echo the variable that was password-prompted
term_A ls
!3 # Pause for 3 seconds
* exit # Close all windows
```

Creates the following terminal:

<img src='sample.gif' width=640 align="middle"/>

## Configuration quirks
* The first item in a COMMAND line must be the session the command should be sent to or `*` to send to all
* If a command starts with `*<N>`, it will pause for `<N>` seconds between each execution
  * (e.g. `*.25 ssh myserver` will execute `ssh myserver` on all machines, spaced apart by .25 seconds
* Any line that starts with `!` pauses for the number of seconds that follow the `!`
* The N'th defined variable can be referenced throughout commands as $N
* Variables that start with a `&` are prompted for on each run of the script
* Variables that start with a `$` are the same, but show up in a password prompt
* `#` is a comment
* There is no guarantee of ordering of commands unless you place a pause between them
