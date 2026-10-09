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
# Menu
# ---------------------------------------------------------------
show_menu() {
    echo ""
    echo "==========================="
    echo "      PS1 Changer"
    echo "==========================="
    echo "  1) Prompt option 1"
    echo "  2) Prompt option 2"
    echo "  3) Prompt option 3"
    echo "  q) Quit"
    echo "==========================="
    echo ""
}

choose_prompt() {
    show_menu
    read -rp "Choose a prompt [1-3, q]: " choice

    case "$choice" in
        1) prompt_one   && echo "✔ Prompt 1 applied." ;;
        2) prompt_two   && echo "✔ Prompt 2 applied." ;;
        3) prompt_three && echo "✔ Prompt 3 applied." ;;
        q|Q) echo "No changes made." ;;
        *)   echo "✘ Invalid choice: '$choice'" ;;
    esac
}

choose_prompt