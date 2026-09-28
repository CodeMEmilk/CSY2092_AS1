# ============================================================
# Variable and Array Declaration
# ============================================================

outputFile="Outputs.txt"
annualFile="AnnualOutputs.txt"

basicSalary=2000

declare -A models=(
    ["A class"]=31095
    ["B class"]=33162
    ["C class"]=42537
    ["E class"]=54437
    ["AMG C65"]=79660
)

declare -a months=(
    January February March April May June
    July August September October November December
)

declare -a modelsSold

salespersonName=""
monthIndex=0
modelCount=0


# ============================================================
# Check Whiptail
# ============================================================

if ! command -v whiptail >/dev/null 2>&1; then

    echo "Error: Whiptail is not installed."
    echo "Please install it before running this program."

    exit 1

fi


# ============================================================
# Function: writeRecord
# ============================================================

writeRecord(){

    local totalSales=0
    local bonus=0
    local monthlySalary=0

    for model in "${modelsSold[@]}"
    do
        (( totalSales += models["$model"] ))
    done

    bonus=$(monthlyBonus "$totalSales")

    monthlySalary=$(( basicSalary + bonus ))

    printf "%s|%s|%s|%d|%d\n" \
        "${months[$monthIndex]}" \
        "$salespersonName" \
        "$(IFS=','; echo "${modelsSold[*]}")" \
        "$totalSales" \
        "$monthlySalary" >> "$outputFile"
}


# ============================================================
# Function: monthlyBonus
# ============================================================

monthlyBonus(){

    local totalSales="$1"
    local bonus=0

    if (( totalSales >= 650000 )); then

        bonus=30000

    elif (( totalSales >= 500000 )); then

        bonus=25000

    elif (( totalSales >= 400000 )); then

        bonus=20000

    elif (( totalSales >= 300000 )); then

        bonus=15000

    elif (( totalSales >= 200000 )); then

        bonus=10000

    fi

    echo "$bonus"
}


# ============================================================
# Function: netTaxedSalary
# ============================================================

netTaxedSalary(){

    local annualSalary="$1"
    local tax=0

    if (( annualSalary <= 12500 )); then

        tax=0

    elif (( annualSalary <= 50000 )); then

        tax=$(( (annualSalary - 12500) * 20 / 100 ))

    elif (( annualSalary <= 150000 )); then

        tax=$(( (50000 - 12500) * 20 / 100 ))
        tax=$(( tax + (annualSalary - 50000) * 40 / 100 ))

    else

        # The assignment does not specify a tax rate
        # above £150,000.

        tax=$(( (50000 - 12500) * 20 / 100 ))
        tax=$(( tax + (150000 - 50000) * 40 / 100 ))

    fi

    echo $(( annualSalary - tax ))
}


# ============================================================
# Function: calculateAnnualSalary
#
# Gets unique names from the first month, then searches the
# entire monthly record file for each salesperson.
# ============================================================

calculateAnnualSalary(){

    local -a records
    local -a salespeople

    local firstMonth=""
    local recordMonth=""
    local recordName=""
    local recordSalary=""

    local salesperson=""
    local annualGross=0
    local annualNet=0

    local recordIndex
    local matchIndex

    declare -A knownSalespeople=()


    # --------------------------------------------------------
    # Read monthly records
    # --------------------------------------------------------

    mapfile -t records < "$outputFile"


    if (( ${#records[@]} == 0 )); then

        whiptail \
            --title "Annual Salary Error" \
            --msgbox "No monthly salary records were found." \
            8 50

        return 1

    fi


    # --------------------------------------------------------
    # Identify first month
    # --------------------------------------------------------

    IFS='|' read -r firstMonth recordName _ _ _ \
        <<< "${records[0]}"


    # --------------------------------------------------------
    # Get unique names from first month
    # --------------------------------------------------------

    salespeople=()

    for (( recordIndex=0; recordIndex<${#records[@]}; recordIndex++ ))
    do

        IFS='|' read -r recordMonth recordName _ _ _ \
            <<< "${records[$recordIndex]}"


        if [[ "$recordMonth" != "$firstMonth" ]]; then
            break
        fi


        if [[ -z "${knownSalespeople[$recordName]}" ]]; then

            salespeople+=("$recordName")
            knownSalespeople["$recordName"]=1

        fi

    done


    # --------------------------------------------------------
    # Create annual output file
    # --------------------------------------------------------

    : > "$annualFile"


    # --------------------------------------------------------
    # Match every salesperson against entire file
    # --------------------------------------------------------

    for salesperson in "${salespeople[@]}"
    do

        annualGross=0


        for (( matchIndex=0; matchIndex<${#records[@]}; matchIndex++ ))
        do

            IFS='|' read -r recordMonth recordName _ _ recordSalary \
                <<< "${records[$matchIndex]}"


            if [[ "$salesperson" == "$recordName" ]]; then

                (( annualGross += recordSalary ))

            fi

        done


        # ----------------------------------------------------
        # Calculate net annual salary
        # ----------------------------------------------------

        annualNet=$(netTaxedSalary "$annualGross")


        # ----------------------------------------------------
        # Save annual record
        # ----------------------------------------------------

        printf "%s|%d|%d\n" \
            "$salesperson" \
            "$annualGross" \
            "$annualNet" >> "$annualFile"

    done

}


# ============================================================
# Function: bubbleSortAnnual
#
# IMPORTANT:
# This is a genuine bubble sort.
# Bash sort command is NOT used.
# ============================================================

bubbleSortAnnual(){

    local -a records

    local recordCount
    local outerIndex
    local innerIndex

    local firstName
    local secondName

    local temporaryRecord


    mapfile -t records < "$annualFile"

    recordCount="${#records[@]}"


    # --------------------------------------------------------
    # Bubble sort
    # --------------------------------------------------------

    for (( outerIndex=0; outerIndex<recordCount-1; outerIndex++ ))
    do

        for (( innerIndex=0;
               innerIndex<recordCount-outerIndex-1;
               innerIndex++ ))
        do

            IFS='|' read -r firstName _ _ \
                <<< "${records[$innerIndex]}"

            IFS='|' read -r secondName _ _ \
                <<< "${records[$((innerIndex + 1))]}"


            if [[ "$firstName" > "$secondName" ]]; then

                temporaryRecord="${records[$innerIndex]}"

                records[$innerIndex]="${records[$((innerIndex + 1))]}"

                records[$((innerIndex + 1))]="$temporaryRecord"

            fi

        done

    done


    # --------------------------------------------------------
    # Rewrite AnnualOutputs.txt
    # --------------------------------------------------------

    : > "$annualFile"

    for record in "${records[@]}"
    do

        echo "$record" >> "$annualFile"

    done

}


# ============================================================
# Function: displayAnnualSalary
# ============================================================

displayAnnualSalary(){

    local salesperson
    local annualGross
    local annualNet

    local displayText=""


    while IFS='|' read -r salesperson annualGross annualNet
    do

        displayText+="Salesperson: $salesperson"$'\n'
        displayText+="Gross Annual Salary: £$annualGross"$'\n'
        displayText+="Net Annual Salary: £$annualNet"$'\n'
        displayText+="--------------------------------"$'\n'

    done < "$annualFile"


    whiptail \
        --title "Annual Salary Results" \
        --scrolltext \
        --msgbox "$displayText" \
        20 70

}


# ============================================================
# Main Section
# ============================================================

# ------------------------------------------------------------
# Create output files
# ------------------------------------------------------------

if [[ ! -f "$outputFile" ]]; then

    touch "$outputFile"

fi

if [[ ! -f "$annualFile" ]]; then

    touch "$annualFile"

fi


# Start fresh
: > "$outputFile"
: > "$annualFile"


# ============================================================
# Welcome Screen
# ============================================================

whiptail \
    --title "Mercedes-Benz Sales Bonus System" \
    --msgbox \
    "Welcome to the Mercedes-Benz Salesperson Salary System.

This program calculates:
• Monthly sales
• Monthly bonus
• Monthly salary
• Annual gross salary
• Annual net salary after tax

Between 3 and 20 salespersons can be entered." \
    14 65


# ============================================================
# Number of Salespersons
# ============================================================

while true
do

    salespersonCount=$(
        whiptail \
            --title "Salesperson Information" \
            --inputbox \
            "Enter number of salespersons (3-20):" \
            10 50 \
            3 \
            3>&1 1>&2 2>&3
    )


    # Cancel
    if [[ $? -ne 0 ]]; then

        whiptail \
            --title "Program Cancelled" \
            --msgbox "No data was saved." \
            8 40

        exit 0

    fi


    # Regular expression validation
    if [[ "$salespersonCount" =~ ^[0-9]+$ ]] &&
       (( salespersonCount >= 3 && salespersonCount <= 20 )); then

        break

    fi


    whiptail \
        --title "Invalid Input" \
        --msgbox \
        "Please enter a whole number between 3 and 20." \
        8 50

done


# ============================================================
# Enter Salesperson Data
# ============================================================

for (( personIndex=1; personIndex<=salespersonCount; personIndex++ ))
do

    # --------------------------------------------------------
    # Select Month
    # --------------------------------------------------------

    while true
    do

        monthInput=$(
            whiptail \
                --title "Salesperson $personIndex - Month" \
                --menu \
                "Select the month:" \
                18 60 12 \
                "January" "January" \
                "February" "February" \
                "March" "March" \
                "April" "April" \
                "May" "May" \
                "June" "June" \
                "July" "July" \
                "August" "August" \
                "September" "September" \
                "October" "October" \
                "November" "November" \
                "December" "December" \
                3>&1 1>&2 2>&3
        )


        if [[ $? -ne 0 ]]; then
            exit 0
        fi


        case "$monthInput" in

            January)   monthIndex=0 ;;
            February)  monthIndex=1 ;;
            March)     monthIndex=2 ;;
            April)     monthIndex=3 ;;
            May)       monthIndex=4 ;;
            June)      monthIndex=5 ;;
            July)      monthIndex=6 ;;
            August)    monthIndex=7 ;;
            September) monthIndex=8 ;;
            October)   monthIndex=9 ;;
            November)  monthIndex=10 ;;
            December)  monthIndex=11 ;;

        esac

        break

    done


    # --------------------------------------------------------
    # Salesperson Name
    # --------------------------------------------------------

    while true
    do

        salespersonName=$(
            whiptail \
                --title "Salesperson $personIndex - Name" \
                --inputbox \
                "Enter salesperson name:" \
                10 60 \
                "" \
                3>&1 1>&2 2>&3
        )


        if [[ $? -ne 0 ]]; then
            exit 0
        fi


        if [[ "$salespersonName" =~ ^[A-Za-z][A-Za-z\ \'-]*$ ]]; then

            break

        fi


        whiptail \
            --title "Invalid Name" \
            --msgbox \
            "Invalid salesperson name.

Use alphabetic characters, spaces,
apostrophes or hyphens only." \
            10 55

    done


    # --------------------------------------------------------
    # Model Selection
    # --------------------------------------------------------

    modelsSold=()
    modelCount=0


    while true
    do

        modelInput=$(
            whiptail \
                --title "$salespersonName - Models Sold" \
                --menu \
                "Select a model sold.

Select 'Finished' when all models have been entered." \
                18 65 6 \
                "A class" "£31,095 average" \
                "B class" "£33,162 average" \
                "C class" "£42,537 average" \
                "E class" "£54,437 average" \
                "AMG C65" "£79,660 average" \
                "FINISHED" "Finish model entry" \
                3>&1 1>&2 2>&3
        )


        if [[ $? -ne 0 ]]; then
            exit 0
        fi


        # ----------------------------------------------------
        # Finish model entry
        # ----------------------------------------------------

        if [[ "$modelInput" == "FINISHED" ]]; then

            if (( modelCount == 0 )); then

                whiptail \
                    --title "No Models Entered" \
                    --msgbox \
                    "At least one model must be entered." \
                    8 50

                continue

            fi

            break

        fi


        # ----------------------------------------------------
        # Store selected model
        #
        # A model can be selected repeatedly.
        # This allows multiple cars of the same model.
        # ----------------------------------------------------

        modelsSold[$modelCount]="$modelInput"

        (( modelCount++ ))


        whiptail \
            --title "Model Added" \
            --msgbox \
            "$modelInput added to $salespersonName's sales." \
            8 50

    done


    # --------------------------------------------------------
    # Write salesperson's monthly record
    # --------------------------------------------------------

    writeRecord

done


# ============================================================
# Calculate Annual Salaries
# ============================================================

calculateAnnualSalary


# ============================================================
# Bubble Sort Annual Salaries
# ============================================================

bubbleSortAnnual


# ============================================================
# Display Annual Results
# ============================================================

displayAnnualSalary


# ============================================================
# Completion Message
# ============================================================

whiptail \
    --title "Processing Complete" \
    --msgbox \
    "The salary calculations have been completed.

Monthly records:
$outputFile

Annual records:
$annualFile

The annual records have been alphabetically
bubble-sorted by salesperson name." \
    12 65