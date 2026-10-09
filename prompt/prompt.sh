```bash
#!/usr/bin/env bash
#
# ps1-changer.sh
#
# Description:
# Displays a whiptail menu allowing the user to select one of three
# shell prompt styles. The selected function updates PS1 in the
# current shell and displays a confirmation message. If the user
# cancels the menu, no changes are made.
#
# Usage: source ps1-changer.sh
#

# ---------------------------------------------------------------
# Global Variables
# ---------------------------------------------------------------
# No global variables are explicitly declared.
# PS1 is a shell variable updated by the selected prompt function.


# ---------------------------------------------------------------
# Prompt Functions
# ---------------------------------------------------------------

# Set the shell prompt to style one.
prompt_one() {
    PS1=""
}

# Set the shell prompt to style two.
prompt_two() {
    PS1=""
}

# Set the shell prompt to style three.
prompt_three() {
    PS1=""
}


# ---------------------------------------------------------------
# Menu Function
# ---------------------------------------------------------------

# Display the prompt selection menu and apply the chosen style.
choose_prompt() {
    local choice

    # Redirect whiptail's menu output so the user's selection
    # is captured in choice instead of being displayed on screen.
    choice=$(whiptail --title "PS1 Changer" \
        --menu "Choose a prompt style:" 15 60 3 \
        "1" "Prompt option 1" \
        "2" "Prompt option 2" \
        "3" "Prompt option 3" \
        3>&1 1>&2 2>&3)

    # A non-zero exit status means the user cancelled the menu.
    if [ $? -ne 0 ]; then
        echo "No changes made."
        return
    fi

    # Call the function matching the user's selection and
    # display a confirmation message after it succeeds.
    case "$choice" in
        1) prompt_one   && echo "✔ Prompt 1 applied." ;;
        2) prompt_two   && echo "✔ Prompt 2 applied." ;;
        3) prompt_three && echo "✔ Prompt 3 applied." ;;
    esac
}


# ---------------------------------------------------------------
# Main Code
# ---------------------------------------------------------------
# Start the menu when this script is sourced.
choose_prompt
```
