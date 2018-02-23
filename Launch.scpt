# Format for .cfg:
# term_A B
# C D terminal_E
# F
# --
# THINGS
# &this will be prompted for
# $this will be password-prompted forn
# --
# term_A echo "Hello!"
# B echo "Goodbye!"
# !1    # Pause for 1 second
# * echo "What's up"
# !2    # Pause for 2 seconds
# F echo $1
# D echo $2
# terminal_E echo $3

on readFile( unixPath )
	return (do shell script "cat '" & unixPath & "'")
end

on getSess(sessions_, names, name)
    repeat with i from 1 to count of names
        repeat with j from 1 to count of (item i of names)
            if item j of (item i of names) equals name
                return item j of (item i of sessions_)
            end if
        end repeat
    end repeat
    display dialog("fail.")
end

tell application "iTerm2"

    set my_path to POSIX path of ((path to me as text) & "::") 

    set f to (choose file of type "cfg" default location POSIX file my_path)

    set cfg_txt to my readFile(POSIX path of f)
    set cfg_list to every paragraph of cfg_txt

# M x N list of the names of the split panels
    set layout to {}
# User-defined variables
    set vars to {}
# Commands to be sent to the panels
    set cmds to {}

    set profile_name to ""

# Read in the configuration file
    set mode to  "LAYOUT"
    repeat with cfg_line in cfg_list
        if (cfg_line as string ) is equal to "--"
            if mode is "LAYOUT"
                set mode to "VARS"
            else if mode is "VARS"
                set mode to "CODE"
            end if
        else
            if mode is "LAYOUT"
                if (text item 1 of (cfg_line as string)) is equal to "^"
                    set profile_name to (text 2 thru end of cfg_line as string)
                else
                    set split_layout to every word of cfg_line
                    copy split_layout to end of layout
                end
            end if
            if mode is "VARS"
# If the variable starts with '$', show a password prompt
                if (text item 1 of (cfg_line as string)) is equal to "$"
                    set passwd to text returned of (display dialog cfg_line default answer "" with hidden answer)
                    set vars to vars & {passwd}
# If the variable starts ith '&', show a normal prompt
                else if (text item 1 of (cfg_line as string)) is "&"
                    set var to text returned of (display dialog cfg_line default answer "")
                    set vars to vars & {var}
                else
                    set vars to vars & {cfg_line}
                end
            end if
            if mode is "CODE"
# Each command is a list of words
               set AppleScript's text item delimiters to " "
               set cmds to cmds & {cfg_line's text items}
               set AppleScript's text item delimiters to {""}
            end if
        end if
    end repeat

# NxM list of created panels
    set sessions_ to {}

    if profile_name is equal to ""
        create window with default profile
    else
        create window with profile profile_name
    end
    set bounds of front window to {300, 30, 1200, 600}
# Get the name of a default session
    set default_name to ((name of session 1 of current tab of current window) as string)

    set names_so_far to {}
# Create one split in each row
    set r_i to 1
    set sessions_created to 1
    repeat with row in layout
        set sessions_ to sessions_ & {{}}
        set curr_ses to (session sessions_created of current tab of current window)
        set (item r_i of sessions_) to (item r_i of sessions_) & {curr_ses}
        if sessions_created does not equal count of layout
            tell curr_ses
                split horizontally with same profile
            end tell
        end if
        tell curr_ses
            select
            set name to item 1 of row
        end tell
        delay .2
        tell curr_ses
            copy name to end of names_so_far
        end
        set r_i to r_i + 1
        set sessions_created to sessions_created + 1
    end repeat

    set r_i to 1
# Create the columns
    repeat with row_ in layout
        set c_i to 1
        repeat with col in row_
            set curr_ses to (item c_i of (item r_i of sessions_))
            tell curr_ses
                set name to item c_i of (item r_i of layout)
            end tell
            delay .2
            tell curr_ses
                copy name to end of names_so_far
            end tell
            if c_i does not equal count of row_
                tell curr_ses
                    split vertically with same profile
                end tell
                set next_ses to 0
# Have to loop over this, because the new split might not be created fast enough
                repeat while next_ses = 0
                    repeat with j from 1 to sessions_created
                        set sess to session j of current tab of current window
                        if not (names_so_far contains (name of sess as string))
                            set next_ses to sess
                        end
                    end
                end
                set sessions_created to sessions_created + 1
                set (item r_i of sessions_) to (item r_i of sessions_) & {next_ses}
            end
            set c_i to c_i + 1
        end
        set r_i to r_i + 1
    end
    delay .1
    set total to sessions_created - 1

    repeat with cmd in cmds
        delay .1
        set name_ to item 1 of cmd
        set sess to 0
        if (text item 1 of name_) equals "!"
            delay (text item 2 of name_ as integer)
        else
            if name_ does not equal "*"
                set sess to my getSess(sessions_, layout, name_)
                if sess = 0
                    display dialog("ERROR, cannot find session with appropriate name " & name_)
                end
           end if
           set text_cmd to ""
           repeat with i from 2 to count of cmd
                set w to item i of cmd
                if count of w is not 0
                    if (text item 1 of w) is "$"
                        set w to item ((text item 2 of w) as integer) of vars
                    end
                    if (text item 1 of w) is "#"
                        exit repeat
                    end
                end if
                set text_cmd to text_cmd & w
                if i does not equal count of cmd
                    set text_cmd to text_cmd & " "
                end if
            end repeat
            if name_ does not equal "*"
                tell sess
                    write text text_cmd
                end tell
            else
                repeat with i from 1 to total
                    tell session i of current tab of current window
                       write text text_cmd
                    end tell
                end repeat
            end if
        end if
    end repeat

end tell
