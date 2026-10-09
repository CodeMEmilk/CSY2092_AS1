```bash
#!/bin/bash

# ============================================================
# Program: Rectangle Area Calculator
# Description:
# Calculates the area of a rectangle using its length and
# breadth. The user can enter dimensions in centimetres or
# inches and display the area in square metres or square
# inches. Uses whiptail for the user interface and bc for
# decimal calculations. The user can perform multiple
# calculations before exiting.
# ============================================================


# ------------------------------------------------------------
# SECTION 1: Global Variable Declarations
# Stores the selected units, rectangle dimensions and result.
# ------------------------------------------------------------
inputFlag="cm"     # Input unit: "cm" (centimetres) or "in" (inches)
outputFlag="m2"    # Output unit: "m2" (square metres) or "in2" (square inches)
length=0
breadth=0
area=0
unit=""


# ------------------------------------------------------------
# SECTION 2: Function Definitions
# ------------------------------------------------------------

# Function: inputPrompt
# Purpose: Lets the user select an input unit and enter the
# rectangle's length and breadth.
# Returns: 0 = success, 1 = invalid selection, 2 = cancelled.
inputPrompt() {

    local choice

    # Display a menu for selecting the input unit.
    # The file descriptor redirections allow whiptail to
    # display its interface while returning the selection.
    choice=$(whiptail --title "Input Unit" \
        --menu "Choose the unit for your rectangle dimensions:" \
        12 60 2 \
        "cm" "Centimeters" \
        "in" "Inches" \
        3>&1 1>&2 2>&3 </dev/tty)

    # A non-zero exit status means the user cancelled the menu.
    [[ $? -ne 0 ]] && return 2

    # Store the selected unit or reject an unexpected value.
    case "$choice" in
        cm|in) inputFlag="$choice" ;;
        *)     return 1 ;;
    esac

    # Set the unit name used in the dimension prompts.
    local unitName
    [[ "$inputFlag" == "cm" ]] && unitName="centimeters" || unitName="inches"

    # Request the rectangle's length.
    length=$(whiptail --title "Rectangle Dimensions" \
        --inputbox "Enter the length in $unitName:" \
        10 60 \
        3>&1 1>&2 2>&3 </dev/tty)

    [[ $? -ne 0 ]] && return 2

    # Request the rectangle's breadth.
    breadth=$(whiptail --title "Rectangle Dimensions" \
        --inputbox "Enter the breadth in $unitName:" \
        10 60 \
        3>&1 1>&2 2>&3 </dev/tty)

    [[ $? -ne 0 ]] && return 2

    return 0
}


# Function: validation
# Purpose: Checks that both dimensions are positive numbers
# in an accepted decimal format.
# Returns: 0 = valid input, 1 = invalid input.
validation() {

    # Regular expressions accept integers and decimals such as
    # 12, 12.5 and 3.142, but reject letters, negative numbers
    # and incorrectly formatted decimals.
    if [[ ! "$length" =~ ^[0-9]+([.][0-9]+)?$ ||
          ! "$breadth" =~ ^[0-9]+([.][0-9]+)?$ ]]; then

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

    # Bash arithmetic does not handle floating-point comparisons.
    # bc -l evaluates each dimension against zero instead.
    if [[ $(echo "$length > 0" | bc -l) -ne 1 ||
          $(echo "$breadth > 0" | bc -l) -ne 1 ]]; then

        whiptail --title "Invalid Input" \
            --msgbox "Length and breadth must be greater than zero." \
            10 55 </dev/tty

        return 1
    fi

    return 0
}


# Function: conversion
# Purpose: Calculates the rectangle's area and converts it
# to the requested output unit.
# Arguments: $1 = input unit, $2 = output unit.
# Output: Prints the converted area; returns 1 for an
# unsupported unit combination.
conversion() {

    local inUnit="$1"
    local outUnit="$2"
    local mult

    # Use bc because Bash's standard arithmetic cannot
    # calculate decimal products accurately as floating-point values.
    mult=$(echo "scale=10; $length * $breadth" | bc -l)

    # Select the conversion formula based on the input and
    # output units. scale=4 limits the displayed decimal places
    # for the converted result.
    case "$inUnit:$outUnit" in
        cm:m2)   echo "scale=4; $mult / 10000"      | bc -l ;;
        cm:in2)  echo "scale=4; $mult * 0.15500031" | bc -l ;;
        in:m2)   echo "scale=4; $mult * 0.00064516" | bc -l ;;
        in:in2)  echo "scale=4; $mult"              | bc -l ;;
        *)
            # Report an error if the unit combination is unsupported.
            whiptail --title "Conversion Error" \
                --msgbox "An error occurred while converting the area." \
                10 55 </dev/tty

            return 1
            ;;
    esac
}


# Function: promptOutput
# Purpose: Lets the user choose the desired area unit.
# Returns: 0 = success, 1 = invalid selection, 2 = cancelled.
promptOutput() {

    local output

    output=$(whiptail --title "Output Unit" \
        --menu "Choose the unit in which you want to display the area:" \
        12 65 2 \
        "m" "Square metres (m²)" \
        "i" "Square inches (in²)" \
        3>&1 1>&2 2>&3 </dev/tty)

    [[ $? -ne 0 ]] && return 2

    # Translate the menu choice into the internal unit identifier.
    case "$output" in
        m|M) outputFlag="m2"  ;;
        i|I) outputFlag="in2" ;;
        *)   return 1 ;;
    esac

    return 0
}


# Function: restart
# Purpose: Asks whether the user wants to calculate another area.
# Returns: 0 = Yes, non-zero = No or cancelled.
restart() {
    whiptail --title "Calculate Another Area?" \
        --yesno "Would you like to enter different dimensions?" \
        10 60 </dev/tty
}


# ------------------------------------------------------------
# SECTION 3: Main Program
# Repeats the calculation until the user cancels, chooses not
# to restart, or the program encounters a handled error.
# ------------------------------------------------------------

while true
do
    # Collect the input unit and rectangle dimensions.
    inputPrompt
    inputStatus=$?

    # Status 2 means the user cancelled; exit the main loop.
    [[ $inputStatus -eq 2 ]] && break

    # Any other non-zero status skips to the next iteration.
    [[ $inputStatus -ne 0 ]] && continue

    # Validate both dimensions before requesting the output unit.
    # Invalid dimensions cause the next loop iteration to begin.
    validation || continue

    # Ask the user which unit should be used for the area.
    promptOutput
    outputStatus=$?

    # Exit if the output menu was cancelled.
    [[ $outputStatus -eq 2 ]] && break

    # Skip the calculation if the selection is invalid.
    [[ $outputStatus -ne 0 ]] && continue

    # Calculate and convert the area. If conversion fails,
    # continue starts the next iteration of the main loop.
    area=$(conversion "$inputFlag" "$outputFlag") || continue

    # Choose the appropriate symbol for the displayed area.
    [[ "$outputFlag" == "m2" ]] && unit="m²" || unit="in²"

    # Display the dimensions, calculated area and output unit.
    whiptail --title "Rectangle Area" \
        --msgbox \
        "Length:  $length $inputFlag
Breadth: $breadth $inputFlag

Area:    $area $unit" \
        12 55 </dev/tty

    # Return to the beginning of the loop if the user chooses Yes.
    # Otherwise, break exits the loop and proceeds to the exit message.
    restart || break
done


# ------------------------------------------------------------
# SECTION 4: Exit Message
# Displayed after the main loop terminates.
# ------------------------------------------------------------
whiptail --title "Area Calculator" \
    --msgbox "Thank you for using the Rectangle Area Calculator." \
    8 55 </dev/tty

exit 0
```
