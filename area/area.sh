# Global variable declaration
breakFlag="false"

length=0
breadth=0

# "cm" for centimeter, "in" for inch
inputFlag="cm"

# "m2" for meter square, "in2" for inch square
outputFlag="m2"

# The following section is for the functions made for this program

inputPrompt(){
    local choice="$1"

    if [[ "$choice" =~ ^[iI]$ ]]; then
        echo -e "Chose inch\n"
        inputFlag="in"

        read -p "Enter value for length: " length
        read -p "Enter value for breadth: " breadth

    elif [[ "$choice" =~ ^[cC]$ ]]; then
        echo -e "Chose Centimeter\n"
        inputFlag="cm"

        read -p "Enter value for length: " length
        read -p "Enter value for breadth: " breadth

    else
        echo "Invalid input unit. Please choose i or c."
        return 1
    fi
}


# Validates user inputs
validation(){

    # Check if values are valid positive numbers
    if [[ "$length" =~ ^[0-9]+([.][0-9]+)?$ &&
          "$breadth" =~ ^[0-9]+([.][0-9]+)?$ ]]; then

        # Check if values are greater than zero
        if [[ $(echo "$length > 0" | bc -l) -eq 1 &&
              $(echo "$breadth > 0" | bc -l) -eq 1 ]]; then
            return 0
        else
            return 1
        fi

    else
        return 1
    fi
}


# The following code involves conversion logic
# for displaying the proper units of the output
conversion(){
    local inputFlag="$1"
    local outputFlag="$2"

    # Calculate area using bc because Bash arithmetic
    # does not support floating point numbers
    mult=$(echo "scale=10; $length * $breadth" | bc -l)

    if [[ "$inputFlag" == "cm" && "$outputFlag" == "m2" ]]; then
        echo "Cm2 to M2"
        echo "scale=4; $mult / 10000" | bc -l

    elif [[ "$inputFlag" == "cm" && "$outputFlag" == "in2" ]]; then
        echo "Centimeter to inch^2"
        echo "scale=4; $mult * 0.15500031" | bc -l

    elif [[ "$inputFlag" == "in" && "$outputFlag" == "m2" ]]; then
        echo "Inch to meter^2"
        echo "scale=4; $mult * 0.00064516" | bc -l

    elif [[ "$inputFlag" == "in" && "$outputFlag" == "in2" ]]; then
        echo "Inch to inch^2"
        echo "scale=4; $mult" | bc -l

    else
        echo "Error occurred"
        return 1
    fi
}


# The following code prompts user to select output type
promptOutput(){
    read -p "Output in m^2 or in in^2? (m/i): " output

    if [[ "$output" =~ ^[mM]$ ]]; then
        outputFlag="m2"

    elif [[ "$output" =~ ^[iI]$ ]]; then
        outputFlag="in2"

    else
        echo "Invalid output selection"
        return 1
    fi
}


# Code responsible for restarting or exiting the program entirely
restart(){
    read -p "Enter 'restart' to re-enter inputs or 'quit' to exit: " tempC

    if [[ "$tempC" =~ ^[rR][eE][sS][tT][aA][rR][tT]$ ]]; then
        breakFlag="false"

    elif [[ "$tempC" =~ ^[qQ][uU][iI][tT]$ ]]; then
        breakFlag="true"

    else
        echo "Invalid choice"
        return 1
    fi
}


while [ "$breakFlag" != "true" ]
do

    read -p "Please choose input units: inches or centimeters (i/c): " choice

    if ! inputPrompt "$choice"; then
        continue
    fi

    if ! validation; then
        echo "Invalid Inputs. Please enter positive numbers."
        continue
    fi

    if ! promptOutput; then
        echo "Invalid output selection"
        continue
    fi

    area=$(conversion "$inputFlag" "$outputFlag")

    echo "Area = $area"

    restart

done