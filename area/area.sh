# ============================================================
# Area of a Rectangle
# Uses whiptail for user interaction
# ============================================================

# ------------------------------------------------------------
# Global variable declaration
# ------------------------------------------------------------
inputFlag="cm"     # "cm" or "in"
outputFlag="m2"    # "m2" or "in2"
length=0
breadth=0
area=0
unit=""


# ------------------------------------------------------------
# Function: inputPrompt
# Prompts user to select input unit and enter dimensions
# Returns: 0 = OK, 1 = invalid selection, 2 = cancel/esc
# ------------------------------------------------------------
inputPrompt(){

    local choice

    # --- Choose input unit ---
    choice=$(whiptail --title "Input Unit" \
        --menu "Choose the unit for your rectangle dimensions:" \
        12 60 2 \
        "cm" "Centimeters" \
        "in" "Inches" \
        3>&1 1>&2 2>&3 </dev/tty)
    [[ $? -ne 0 ]] && return 2

    case "$choice" in
        cm|in) inputFlag="$choice" ;;
        *)     return 1 ;;
    esac

    # --- Length ---
    local unitName
    [[ "$inputFlag" == "cm" ]] && unitName="centimeters" || unitName="inches"

    length=$(whiptail --title "Rectangle Dimensions" \
        --inputbox "Enter the length in $unitName:" \
        10 60 \
        3>&1 1>&2 2>&3 </dev/tty)
    [[ $? -ne 0 ]] && return 2

    # --- Breadth ---
    breadth=$(whiptail --title "Rectangle Dimensions" \
        --inputbox "Enter the breadth in $unitName:" \
        10 60 \
        3>&1 1>&2 2>&3 </dev/tty)
    [[ $? -ne 0 ]] && return 2

    return 0
}


# ------------------------------------------------------------
# Function: validation
# Validates length and breadth using regular expressions
# Returns: 0 = valid, 1 = invalid
# ------------------------------------------------------------
validation(){

    # Accepts: 12, 12.5, 3.142  |  Rejects: abc, -12, 12.5.6, .5
    if [[ ! "$length"    =~ ^[0-9]+([.][0-9]+)?$ ||
          ! "$breadth"   =~ ^[0-9]+([.][0-9]+)?$ ]]; then

        whiptail --title "Invalid Input" \
            --msgbox \
            "Please enter valid positive numbers.

Examples:
12
12.5
3.142

Letters, negative numbers and incorrectly formatted decimals are not allowed." \
            14 65 </dev/tty
        return 1
    fi

    # Must be greater than zero
    if [[ $(echo "$length > 0"  | bc -l) -ne 1 ||
          $(echo "$breadth > 0" | bc -l) -ne 1 ]]; then

        whiptail --title "Invalid Input" \
            --msgbox "Length and breadth must be greater than zero." \
            10 55 </dev/tty
        return 1
    fi

    return 0
}


# ------------------------------------------------------------
# Function: conversion
# Calculates and converts the area
# Args: $1 = input unit, $2 = output unit
# Echoes the converted area, or returns 1 on bad combination
# ------------------------------------------------------------
conversion(){

    local inUnit="$1"
    local outUnit="$2"
    local mult

    # Bash arithmetic can't do floats — use bc
    mult=$(echo "scale=10; $length * $breadth" | bc -l)

    case "$inUnit:$outUnit" in
        cm:m2)   echo "scale=4; $mult / 10000"          | bc -l ;;
        cm:in2)  echo "scale=4; $mult * 0.15500031"     | bc -l ;;
        in:m2)   echo "scale=4; $mult * 0.00064516"     | bc -l ;;
        in:in2)  echo "scale=4; $mult"                  | bc -l ;;
        *)
            whiptail --title "Conversion Error" \
                --msgbox "An error occurred while converting the area." \
                10 55 </dev/tty
            return 1
            ;;
    esac
}


# ------------------------------------------------------------
# Function: promptOutput
# Prompts user to select desired output unit
# Returns: 0 = OK, 1 = invalid, 2 = cancel/esc
# ------------------------------------------------------------
promptOutput(){

    local output

    output=$(whiptail --title "Output Unit" \
        --menu "Choose the unit in which you want to display the area:" \
        12 65 2 \
        "m" "Square metres (m²)" \
        "i" "Square inches (in²)" \
        3>&1 1>&2 2>&3 </dev/tty)
    [[ $? -ne 0 ]] && return 2

    case "$output" in
        m|M) outputFlag="m2"  ;;
        i|I) outputFlag="in2" ;;
        *)   return 1 ;;
    esac

    return 0
}


# ------------------------------------------------------------
# Function: restart
# Returns 0 to restart, 1 to quit
# ------------------------------------------------------------
restart(){
    whiptail --title "Calculate Another Area?" \
        --yesno "Would you like to enter different dimensions?" \
        10 60 </dev/tty
}


# ------------------------------------------------------------
# Main Program Loop
# ------------------------------------------------------------
while true
do
    inputPrompt
    inputStatus=$?
    [[ $inputStatus -eq 2 ]] && break          # cancel/esc = exit
    [[ $inputStatus -ne 0 ]] && continue       # bad selection

    validation || continue

    promptOutput
    outputStatus=$?
    [[ $outputStatus -eq 2 ]] && break
    [[ $outputStatus -ne 0 ]] && continue

    area=$(conversion "$inputFlag" "$outputFlag") || continue

    [[ "$outputFlag" == "m2" ]] && unit="m²" || unit="in²"

    whiptail --title "Rectangle Area" \
        --msgbox \
        "Length:  $length $inputFlag
Breadth: $breadth $inputFlag

Area:    $area $unit" \
        12 55 </dev/tty

    restart || break
done


# ------------------------------------------------------------
# Exit message
# ------------------------------------------------------------
whiptail --title "Area Calculator" \
    --msgbox "Thank you for using the Rectangle Area Calculator." \
    8 55 </dev/tty

exit 0