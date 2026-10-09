#
# ps1-changer.sh - Simple PS1 prompt changer
# Usage: source ps1-changer.sh
#

# ---------------------------------------------------------------
# Prompt placeholder
# ---------------------------------------------------------------

prompt_one() {
    PS1=""
}

prompt_two() {
    PS1=""
}

prompt_three() {
    PS1=""
}

# ---------------------------------------------------------------
# Whiptail menu
# ---------------------------------------------------------------
choose_prompt() {
    local choice
    choice=$(whiptail --title "PS1 Changer" \
        --menu "Choose a prompt style:" 15 60 3 \
        "1" "Prompt option 1" \
        "2" "Prompt option 2" \
        "3" "Prompt option 3" \
        3>&1 1>&2 2>&3)

    # User cancelled (Esc / Cancel button)
    if [ $? -ne 0 ]; then
        echo "No changes made."
        return
    fi

    case "$choice" in
        1) prompt_one   && echo "✔ Prompt 1 applied." ;;
        2) prompt_two   && echo "✔ Prompt 2 applied." ;;
        3) prompt_three && echo "✔ Prompt 3 applied." ;;
    esac
}

choose_prompt