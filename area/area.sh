```bash
# ============================================================
# Area of a Rectangle
# Uses whiptail for user interaction
# ============================================================

# ------------------------------------------------------------
# Global variable declaration
# ------------------------------------------------------------

# "cm" for centimeter, "in" for inch
inputFlag="cm"

# "m2" for meter square, "in2" for inch square
outputFlag="m2"

breakFlag="false"

length=0
breadth=0


# ------------------------------------------------------------
# Function: inputPrompt
# Prompts user to select input unit and enter dimensions
# ------------------------------------------------------------

inputPrompt(){

    local choice
    local inputData

    choice=$(whiptail --title "Input Unit" \
        --menu "Choose the unit for your rectangle dimensions:" \
        12 60 2 \
        "cm" "Centimeters" \
        "in" "Inches" \
        3>&1 1>&2 2>&3)

    # User pressed Cancel or Esc
    if [[ $? -ne 0 ]]; then
        return 2
    fi

    if [[ "$choice" == "in" ]]; then
        inputFlag="in"

    elif [[ "$choice" == "cm" ]]; then
        inputFlag="cm"

    else
        return 1
    fi


    # --------------------------------------------------------
    # Get length
    # --------------------------------------------------------

    length=$(whiptail --title "Rectangle Dimensions" \
        --inputbox "Enter the length in $(
            [[ "$inputFlag" == "cm" ]] && echo "centimeters" || echo "inches"
        ):" \
        10 60 \
        3>&1 1>&2 2>&3)

    if [[ $? -ne 0 ]]; then
        return 2
    fi


    # --------------------------------------------------------
    # Get breadth
    # --------------------------------------------------------

    breadth=$(whiptail --title "Rectangle Dimensions" \
        --inputbox "Enter the breadth in $(
            [[ "$inputFlag" == "cm" ]] && echo "centimeters" || echo "inches"
        ):" \
        10 60 \
        3>&1 1>&2 2>&3)

    if [[ $? -ne 0 ]]; then
        return 2
    fi

    return 0
}


# ------------------------------------------------------------
# Function: validation
# Validates length and breadth using regular expressions
# ------------------------------------------------------------

validation(){

    # Check that both values are valid positive numbers.
    #
    # Accepted:
    #   12
    #   12.5
    #   3.142
    #
    # Rejected:
    #   abc
    #   -12
    #   12.5.6
    #   .5

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
            14 65

        return 1
    fi


    # --------------------------------------------------------
    # Check that values are greater than zero
    # --------------------------------------------------------

    if [[ $(echo "$length > 0" | bc -l) -ne 1 ||
          $(echo "$breadth > 0" | bc -l) -ne 1 ]]; then

        whiptail --title "Invalid Input" \
            --msgbox \
            "Length and breadth must be greater than zero." \
            10 55

        return 1
    fi

    return 0
}


# ------------------------------------------------------------
# Function: conversion
# Calculates and converts the area
# ------------------------------------------------------------

conversion(){

    local inputFlag="$1"
    local outputFlag="$2"

    # Calculate area using bc because Bash arithmetic
    # does not support floating-point numbers.
    mult=$(echo "scale=10; $length * $breadth" | bc -l)


    if [[ "$inputFlag" == "cm" && "$outputFlag" == "m2" ]]; then

        # cm² -> m²
        echo "scale=4; $mult / 10000" | bc -l


    elif [[ "$inputFlag" == "cm" && "$outputFlag" == "in2" ]]; then

        # cm² -> in²
        # 1 cm² = 0.15500031 in²
        echo "scale=4; $mult * 0.15500031" | bc -l


    elif [[ "$inputFlag" == "in" && "$outputFlag" == "m2" ]]; then

        # in² -> m²
        # 1 in² = 0.00064516 m²
        echo "scale=4; $mult * 0.00064516" | bc -l


    elif [[ "$inputFlag" == "in" && "$outputFlag" == "in2" ]]; then

        # in² -> in²
        echo "scale=4; $mult" | bc -l


    else

        whiptail --title "Conversion Error" \
            --msgbox "An error occurred while converting the area." \
            10 55

        return 1

    fi
}


# ------------------------------------------------------------
# Function: promptOutput
# Prompts user to select desired output unit
# ------------------------------------------------------------

promptOutput(){

    local output

    output=$(whiptail --title "Output Unit" \
        --menu "Choose the unit in which you want to display the area:" \
        12 65 2 \
        "m" "Square metres (m²)" \
        "i" "Square inches (in²)" \
        3>&1 1>&2 2>&3)

    # User pressed Cancel or Esc
    if [[ $? -ne 0 ]]; then
        return 2
    fi


    if [[ "$output" =~ ^[mM]$ ]]; then

        outputFlag="m2"

    elif [[ "$output" =~ ^[iI]$ ]]; then

        outputFlag="in2"

    else

        whiptail --title "Invalid Output" \
            --msgbox "Invalid output selection." \
            8 50

        return 1
    fi

    return 0
}


# ------------------------------------------------------------
# Function: restart
# Gives user option to restart or quit
# ------------------------------------------------------------

restart(){

    if whiptail --title "Calculate Another Area?" \
        --yesno \
        "Would you like to enter different dimensions?" \
        10 60
    then

        breakFlag="false"
        return 0

    else

        breakFlag="true"
        return 0

    fi
}


# ------------------------------------------------------------
# Main Program Loop
# ------------------------------------------------------------

while [[ "$breakFlag" != "true" ]]
do

    # --------------------------------------------------------
    # Get input unit and dimensions
    # --------------------------------------------------------

    inputPrompt

    inputStatus=$?

    # Cancel/Esc = exit program
    if [[ $inputStatus -eq 2 ]]; then
        break
    fi

    # Something went wrong with input selection
    if [[ $inputStatus -ne 0 ]]; then
        continue
    fi


    # --------------------------------------------------------
    # Validate numerical input
    # --------------------------------------------------------

    if ! validation; then
        continue
    fi


    # --------------------------------------------------------
    # Select output unit
    # --------------------------------------------------------

    promptOutput

    outputStatus=$?

    # Cancel/Esc = exit program
    if [[ $outputStatus -eq 2 ]]; then
        break
    fi

    if [[ $outputStatus -ne 0 ]]; then
        continue
    fi


    # --------------------------------------------------------
    # Calculate area
    # --------------------------------------------------------

    area=$(conversion "$inputFlag" "$outputFlag")


    # --------------------------------------------------------
    # Display result
    # --------------------------------------------------------

    if [[ "$outputFlag" == "m2" ]]; then

        unit="m²"

    else

        unit="in²"

    fi


    whiptail --title "Rectangle Area" \
        --msgbox \
        "Length:  $length $inputFlag
Breadth: $breadth $inputFlag

Area:    $area $unit" \
        12 55


    # --------------------------------------------------------
    # Restart or quit
    # --------------------------------------------------------

    restart

done


# ------------------------------------------------------------
# Exit message
# ------------------------------------------------------------

whiptail --title "Area Calculator" \
    --msgbox "Thank you for using the Rectangle Area Calculator." \
    8 55

exit 0
```
