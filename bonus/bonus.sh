# ============================================================
# Whiptail Interface
# ============================================================

# ------------------------------------------------------------
# Variable and Array Declaration
# ------------------------------------------------------------

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
    "January"
    "February"
    "March"
    "April"
    "May"
    "June"
    "July"
    "August"
    "September"
    "October"
    "November"
    "December"
)

# Stores all salesperson names for the year.
declare -a salespersonNames

# Stores models sold by the currently selected salesperson.
declare -a modelsSold

salespersonName=""
monthIndex=0
modelCount=0


# ============================================================
# Whiptail Availability Check
# ============================================================

if ! command -v whiptail >/dev/null 2>&1; then
    echo "Error: Whiptail is not installed."
    echo "Install it using:"
    echo "sudo apt install whiptail"
    exit 1
fi


# ============================================================
# Welcome Message
# ============================================================

whiptail \
    --title "Salesperson Salary System" \
    --msgbox \
    "Welcome to the Car Salesperson Salary System." \
    10 60


# ============================================================
# Function: Select Month
# ============================================================

selectMonth(){

    local selectedMonth

    selectedMonth=$(
        whiptail \
            --title "Month Selection" \
            --menu "Select the month:" \
            18 45 12 \
            1 "January" \
            2 "February" \
            3 "March" \
            4 "April" \
            5 "May" \
            6 "June" \
            7 "July" \
            8 "August" \
            9 "September" \
            10 "October" \
            11 "November" \
            12 "December" \
            --nocancel \
            3>&1 1>&2 2>&3
    )

    if [[ -z "$selectedMonth" ]]; then
        return 1
    fi

    monthIndex=$((selectedMonth - 1))

    return 0
}


# ============================================================
# Function: Enter Salesperson Names
# ============================================================

enterSalespersonNames(){

    local salespersonIndex
    local enteredName

    salespersonNames=()

    for (( salespersonIndex=0;
           salespersonIndex<salespersonCount;
           salespersonIndex++ )); do

        while true; do

            enteredName=$(
                whiptail \
                    --title "Salesperson Setup" \
                    --inputbox \
                    "Enter name for salesperson $((salespersonIndex + 1)) of $salespersonCount:" \
                    10 60 \
                    "" \
                    --nocancel \
                    3>&1 1>&2 2>&3
            )

            # ------------------------------------------------
            # Name validation
            # ------------------------------------------------

            if [[ "$enteredName" =~ ^[A-Za-z][A-Za-z\ ]*$ ]]; then

                # Remove accidental leading/trailing spaces.
                enteredName="${enteredName#"${enteredName%%[![:space:]]*}"}"
                enteredName="${enteredName%"${enteredName##*[![:space:]]}"}"

                if [[ -n "$enteredName" ]]; then
                    break
                fi
            fi

            whiptail \
                --title "Invalid Name" \
                --msgbox \
                "Please enter a valid salesperson name.\n\n\
Only alphabetic characters and spaces are allowed." \
                10 60

        done

        salespersonNames+=("$enteredName")

    done
}


# ============================================================
# Function: Show Salesperson List
# ============================================================

displaySalespersonList(){

    local displayText=""
    local salespersonIndex

    for (( salespersonIndex=0;
           salespersonIndex<${#salespersonNames[@]};
           salespersonIndex++ )); do

        displayText+="$((salespersonIndex + 1)). ${salespersonNames[$salespersonIndex]}\n"

    done

    whiptail \
        --title "Salesperson List" \
        --msgbox \
        "The following salespersons have been registered:\n\n\
$displayText" \
        15 60
}


# ============================================================
# Function: Select Models
# ============================================================

selectModels(){

    modelsSold=()
    modelCount=0

    while true; do

        local selectedModel

        selectedModel=$(
            whiptail \
                --title "Vehicle Selection" \
                --menu \
                "Entering models sold for:\n\n\
$salespersonName\n\n\
Select a vehicle sold.\n\
Select FINISHED when all vehicles have been entered." \
                20 65 7 \
                1 "A class       (£31,095)" \
                2 "B class       (£33,162)" \
                3 "C class       (£42,537)" \
                4 "E class       (£54,437)" \
                5 "AMG C65       (£79,660)" \
                6 "FINISHED" \
                --nocancel \
                3>&1 1>&2 2>&3
        )

        case "$selectedModel" in

            1)
                modelsSold+=("A class")
                ((modelCount++))
                ;;

            2)
                modelsSold+=("B class")
                ((modelCount++))
                ;;

            3)
                modelsSold+=("C class")
                ((modelCount++))
                ;;

            4)
                modelsSold+=("E class")
                ((modelCount++))
                ;;

            5)
                modelsSold+=("AMG C65")
                ((modelCount++))
                ;;

            6)
                if (( modelCount == 0 )); then

                    whiptail \
                        --title "No Vehicles Selected" \
                        --msgbox \
                        "At least one vehicle must be entered." \
                        8 50

                else
                    break
                fi
                ;;

            *)
                return 1
                ;;

        esac

    done
}


# ============================================================
# Function: Calculate Monthly Bonus
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
# Function: Write Monthly Record
# ============================================================

writeRecord(){

    local totalSales=0
    local bonus=0
    local monthlySalary=0
    local model

    for model in "${modelsSold[@]}"; do
        (( totalSales += models["$model"] ))
    done

    bonus=$(monthlyBonus "$totalSales")

    monthlySalary=$((basicSalary + bonus))

    printf "%s|%s|%s|%d|%d\n" \
        "${months[$monthIndex]}" \
        "$salespersonName" \
        "$(IFS=','; echo "${modelsSold[*]}")" \
        "$totalSales" \
        "$monthlySalary" >> "$outputFile"
}


# ============================================================
# Function: Calculate Annual Net Salary
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

        tax=$(( tax +
            (annualSalary - 50000) * 40 / 100 ))

    else

        tax=$(( (50000 - 12500) * 20 / 100 ))

        tax=$(( tax +
            (150000 - 50000) * 40 / 100 ))

    fi

    echo $((annualSalary - tax))
}


# ============================================================
# Function: Calculate Annual Salary
# ============================================================

calculateAnnualSalary(){

    local -a records

    local salesperson
    local record
    local recordName
    local recordSalary
    local firstMonth

    local annualGross
    local annualNet

    mapfile -t records < "$outputFile"

    : > "$annualFile"

    if (( ${#records[@]} == 0 )); then
        return 1
    fi


    # --------------------------------------------------------
    # First month is used only to establish the salesperson
    # order.
    # --------------------------------------------------------

    IFS='|' read -r firstMonth _ _ _ _ <<< "${records[0]}"


    # --------------------------------------------------------
    # Use the salespersonNames array instead of extracting
    # names from the monthly records.
    #
    # This is possible because the names are fixed for the
    # entire year.
    # --------------------------------------------------------

    for salesperson in "${salespersonNames[@]}"; do

        annualGross=0

        for record in "${records[@]}"; do

            IFS='|' read -r \
                _ \
                recordName \
                _ \
                _ \
                recordSalary <<< "$record"

            if [[ "$recordName" == "$salesperson" ]]; then
                (( annualGross += recordSalary ))
            fi

        done

        annualNet=$(netTaxedSalary "$annualGross")

        printf "%s|%d|%d\n" \
            "$salesperson" \
            "$annualGross" \
            "$annualNet" >> "$annualFile"

    done
}


# ============================================================
# Function: Bubble Sort AnnualOutputs.txt
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


    for (( outerIndex=0;
           outerIndex<recordCount-1;
           outerIndex++ )); do

        for (( innerIndex=0;
               innerIndex<recordCount-outerIndex-1;
               innerIndex++ )); do

            IFS='|' read -r firstName _ _ <<< \
                "${records[$innerIndex]}"

            IFS='|' read -r secondName _ _ <<< \
                "${records[$((innerIndex + 1))]}"


            if [[ "$firstName" > "$secondName" ]]; then

                temporaryRecord="${records[$innerIndex]}"

                records[$innerIndex]=\
                    "${records[$((innerIndex + 1))]}"

                records[$((innerIndex + 1))]=\
                    "$temporaryRecord"

            fi

        done

    done


    : > "$annualFile"

    for record in "${records[@]}"; do
        echo "$record" >> "$annualFile"
    done
}


# ============================================================
# Function: Display Annual Salary
# ============================================================

displayAnnualSalary(){

    local -a records
    local displayText=""
    local salesperson
    local annualGross
    local annualNet

    mapfile -t records < "$annualFile"


    for record in "${records[@]}"; do

        IFS='|' read -r \
            salesperson \
            annualGross \
            annualNet <<< "$record"

        displayText+="Name: $salesperson\n"
        displayText+="Annual Gross Salary: £$annualGross\n"
        displayText+="Annual Net Salary: £$annualNet\n"
        displayText+="--------------------------------\n"

    done


    whiptail \
        --title "Annual Salary Results" \
        --scrolltext \
        --msgbox \
        "$displayText" \
        20 70
}


# ============================================================
# Main Program
# ============================================================

: > "$outputFile"
: > "$annualFile"


# ============================================================
# STEP 1: Number of Salespersons
# ============================================================

while true; do

    salespersonCount=$(
        whiptail \
            --title "Salesperson Setup" \
            --inputbox \
            "Enter number of salespersons (3-20):" \
            10 60 \
            "" \
            --nocancel \
            3>&1 1>&2 2>&3
    )

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
# STEP 2: Enter Salesperson Names ONCE
# ============================================================

enterSalespersonNames

displaySalespersonList


# ============================================================
# STEP 3: Enter Monthly Sales
# ============================================================

for (( currentMonth=0;
       currentMonth<12;
       currentMonth++ )); do

    monthIndex="$currentMonth"


    whiptail \
        --title "Monthly Data Entry" \
        --msgbox \
        "Entering sales data for:\n\n\
${months[$monthIndex]}\n\n\
There are $salespersonCount salespersons." \
        10 60


    # --------------------------------------------------------
    # Loop through the stored salesperson names.
    # --------------------------------------------------------

    for (( salespersonIndex=0;
           salespersonIndex<salespersonCount;
           salespersonIndex++ )); do

        salespersonName="${salespersonNames[$salespersonIndex]}"


        whiptail \
            --title "${months[$monthIndex]}" \
            --msgbox \
            "Entering models sold for:\n\n\
$salespersonName\n\n\
Month: ${months[$monthIndex]}" \
            11 60


        # ----------------------------------------------------
        # Only models are entered here.
        # ----------------------------------------------------

        selectModels

        # ----------------------------------------------------
        # writeRecord() automatically gets:
        #
        #   month       -> monthIndex
        #   salesperson -> salespersonName
        #   models      -> modelsSold
        #
        # ----------------------------------------------------

        writeRecord

    done

done


# ============================================================
# STEP 4: Calculate Annual Salaries
# ============================================================

whiptail \
    --title "Processing" \
    --infobox \
    "Calculating annual salaries..." \
    8 50

sleep 1

calculateAnnualSalary


# ============================================================
# STEP 5: Alphabetical Bubble Sort
# ============================================================

whiptail \
    --title "Processing" \
    --infobox \
    "Sorting annual salaries alphabetically..." \
    8 50

sleep 1

bubbleSortAnnual


# ============================================================
# STEP 6: Display Results
# ============================================================

displayAnnualSalary


# ============================================================
# STEP 7: Completion
# ============================================================

whiptail \
    --title "Program Complete" \
    --msgbox \
    "Annual salary calculations have been completed.\n\n\
Monthly records:\n$outputFile\n\n\
Annual results:\n$annualFile" \
    12 65


exit 0