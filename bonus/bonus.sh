# Bonus Script
# -----------------------------
# Records each salesperson's car sales for all 12 months, calculates monthly
# bonuses and salaries, and saves monthly records to Outputs.txt. It then
# totals each salesperson's annual gross salary, estimates annual net salary
# using the tax bands below, sorts the annual results by name, and displays
# them. The program uses Whiptail for interactive input and output.
#
# Requirements: Bash with associative-array support and whiptail.
# ============================================================

# ------------------------------------------------------------
# GLOBAL VARIABLES, CONSTANTS, AND ARRAYS
# ------------------------------------------------------------

outputFile="Outputs.txt"
annualFile="AnnualOutputs.txt"

basicSalary=2000

# Single source of truth for model prices.
declare -A models=(
    ["A class"]=31095
    ["B class"]=33162
    ["C class"]=42537
    ["E class"]=54437
    ["AMG C65"]=79660
)

# Ordered list of model names (parallel to the form fields).
declare -a modelNames=(
    "A class"
    "B class"
    "C class"
    "E class"
    "AMG C65"
)

declare -a months=(
    "January" "February" "March" "April" "May" "June"
    "July" "August" "September" "October" "November" "December"
)

declare -a salespersonNames
declare -a modelsSold        # one entry per unit sold
salespersonName=""
monthIndex=0

# ============================================================
# DEPENDENCY CHECK
# ============================================================

if ! command -v whiptail >/dev/null 2>&1; then
    echo "Error: Whiptail is not installed."
    echo "Install it using:  sudo apt install whiptail"
    exit 1
fi

# ============================================================
# WELCOME MESSAGE
# ============================================================

whiptail --title "Salesperson Salary System" \
         --msgbox "Welcome to the Car Salesperson Salary System." \
         10 60

# ============================================================
# FUNCTIONS: INPUT AND MONTHLY SALES
# ============================================================
# Helper: join array elements with a delimiter
# ============================================================

# Join array elements using the supplied delimiter.
joinBy() {
    local IFS="$1"
    shift
    echo "$*"
}

# ============================================================
# Function: Enter Salesperson Names
# ============================================================

# Prompt for each salesperson's name and repeat until it passes validation.
enterSalespersonNames() {
    local salespersonIndex enteredName

    salespersonNames=()

    for (( salespersonIndex=0;
           salespersonIndex<salespersonCount;
           salespersonIndex++ )); do

        while true; do
            enteredName=$(
                whiptail --title "Salesperson Setup" \
                         --inputbox \
                         "Enter name for salesperson $((salespersonIndex + 1)) of $salespersonCount:" \
                         10 60 "" \
                         --nocancel \
                         3>&1 1>&2 2>&3
            )

                    # Trim leading and trailing whitespace before checking the name.
            enteredName="${enteredName#"${enteredName%%[![:space:]]*}"}"
            enteredName="${enteredName%"${enteredName##*[![:space:]]}"}"

            if [[ "$enteredName" =~ ^[A-Za-z][A-Za-z\ ]*$ && -n "$enteredName" ]]; then
                break
            fi

            whiptail --title "Invalid Name" \
                     --msgbox \
                     "Please enter a valid salesperson name.\n\nOnly alphabetic characters and spaces are allowed." \
                     10 60
        done

        salespersonNames+=("$enteredName")
    done
}

# ============================================================
# Function: Show Salesperson List
# ============================================================

# Display registered salesperson names in registration order.
displaySalespersonList() {
    local displayText="" i
    for (( i=0; i<${#salespersonNames[@]}; i++ )); do
        displayText+="$((i + 1)). ${salespersonNames[$i]}\n"
    done

    whiptail --title "Salesperson List" \
             --msgbox \
             "The following salespersons have been registered:\n\n$displayText" \
             15 60
}

# ============================================================
# Function: Select Models (single form, quantity per model)
# ============================================================
#
# Presents one whiptail form listing every model with its
# price and a quantity field. The user types a whole number
# next to each model. modelsSold is then expanded so that
# each model name appears once per unit sold.
#
# Submitting with all zeros is permitted: modelsSold will be
# empty for this salesperson/month, and writeRecord will
# record zero sales with the basic salary.
#
# Collect model quantities and store one model name per unit sold.
selectModels() {
    modelsSold=()

    # Build alternating label/default-value arguments for the Whiptail form.
    local -a formArgs=()
    local i
    for (( i=0; i<${#modelNames[@]}; i++ )); do
        formArgs+=("${modelNames[$i]} (£${models[${modelNames[$i]}]}):" "0")
    done

    local result
    result=$(
        whiptail --title "Vehicle Selection" \
                 --form \
                 "Enter quantity sold for each model.\n\nSalesperson: $salespersonName\nMonth: ${months[$monthIndex]}" \
                 20 65 7 \
                 "${formArgs[@]}" \
                 --nocancel \
                 3>&1 1>&2 2>&3
    ) || return 1

    # Whiptail returns one quantity per line, in the same order as modelNames.
    local -a quantities
    mapfile -t quantities <<< "$result"

    # Store one model name per unit so monthly totals can sum each car's price.
    # Invalid/empty entries are treated as zero.
    for (( i=0; i<${#modelNames[@]}; i++ )); do
        local qty="${quantities[$i]:-0}"
        if [[ ! "$qty" =~ ^[0-9]+$ ]]; then
            qty=0
        fi

        local j
        for (( j=0; j<qty; j++ )); do
            modelsSold+=("${modelNames[$i]}")
        done
    done
}

# ============================================================
# Function: Calculate Monthly Bonus
# ============================================================

# Return the bonus amount for the supplied monthly sales total.
monthlyBonus() {
    local totalSales="$1"

    if   (( totalSales >= 650000 )); then echo 30000
    elif (( totalSales >= 500000 )); then echo 25000
    elif (( totalSales >= 400000 )); then echo 20000
    elif (( totalSales >= 300000 )); then echo 15000
    elif (( totalSales >= 200000 )); then echo 10000
    else                                  echo 0
    fi
}

# ============================================================
# Function: Write Monthly Record
# ============================================================

# Calculate monthly sales, bonus, and salary; append the result to Outputs.txt.
writeRecord() {
    local totalSales=0 bonus monthlySalary model

    # Sum the price of every unit recorded in modelsSold.
    for model in "${modelsSold[@]}"; do
        (( totalSales += models["$model"] ))
    done

    bonus=$(monthlyBonus "$totalSales")
    monthlySalary=$((basicSalary + bonus))

    printf "%s|%s|%s|%d|%d\n" \
        "${months[$monthIndex]}" \
        "$salespersonName" \
        "$(joinBy ',' "${modelsSold[@]}")" \
        "$totalSales" \
        "$monthlySalary" >> "$outputFile"
}

# ============================================================
# FUNCTIONS: ANNUAL PROCESSING AND OUTPUT
# ============================================================
# Function: Calculate Annual Net Salary
# ============================================================
#
# UK-style brackets:
#   0 – 12,500      : 0%
#   12,500 – 50,000 : 20%
#   50,000 – 150,000: 40%
#   above 150,000   : 45%
#
# Calculate annual net salary by applying the progressive tax bands below.
netTaxedSalary() {
    local annualSalary="$1"
    local tax=0

    if (( annualSalary > 12500 )); then
        local band=$(( annualSalary < 50000 ? annualSalary : 50000 ))
        tax=$(( tax + (band - 12500) * 20 / 100 ))
    fi

    if (( annualSalary > 50000 )); then
        local band=$(( annualSalary < 150000 ? annualSalary : 150000 ))
        tax=$(( tax + (band - 50000) * 40 / 100 ))
    fi

    if (( annualSalary > 150000 )); then
        tax=$(( tax + (annualSalary - 150000) * 45 / 100 ))
    fi

    echo $((annualSalary - tax))
}

# ============================================================
# Function: Calculate Annual Salary
# ============================================================

# Aggregate monthly salaries, calculate annual net salary, and write annual records.
calculateAnnualSalary() {
    local -a records
    local -A grossByPerson

    mapfile -t records < "$outputFile"
    : > "$annualFile"

    (( ${#records[@]} == 0 )) && return 1

    # Add each monthly salary to the matching salesperson's annual total.
    # Names are normalised (trim whitespace/CR) so they match
    # what is stored in salespersonNames[].
    local record recordName recordSalary
    for record in "${records[@]}"; do
        # Strip any trailing CR that may have crept in (CRLF file).
        record="${record%$'\r'}"

        IFS='|' read -r _ recordName _ _ recordSalary <<< "$record"

        # Trim leading/trailing whitespace from the name.
        recordName="${recordName#"${recordName%%[![:space:]]*}"}"
        recordName="${recordName%"${recordName##*[![:space:]]}"}"

        (( grossByPerson["$recordName"] += recordSalary ))
    done

    # Preserve registration order here; the following function sorts the records.
    local salesperson annualGross annualNet
    for salesperson in "${salespersonNames[@]}"; do
        annualGross="${grossByPerson[$salesperson]:-0}"
        annualNet=$(netTaxedSalary "$annualGross")
        printf "%s|%d|%d\n" "$salesperson" "$annualGross" "$annualNet" >> "$annualFile"
    done
}

# ============================================================
# Function: Bubble Sort AnnualOutputs.txt (by name)
# ============================================================

# Sort annual salary records alphabetically by salesperson name.
bubbleSortAnnual() {
    local -a records
    local recordCount outer inner
    local firstName secondName temporary

    mapfile -t records < "$annualFile"
    recordCount="${#records[@]}"

    for (( outer=0; outer<recordCount-1; outer++ )); do
        for (( inner=0; inner<recordCount-outer-1; inner++ )); do
            IFS='|' read -r firstName _ _ <<< "${records[$inner]}"
            IFS='|' read -r secondName _ _ <<< "${records[$((inner + 1))]}"

            # Swap adjacent records if their names are out of alphabetical order.
            if [[ "$firstName" > "$secondName" ]]; then
                temporary="${records[$inner]}"
                records[$inner]="${records[$((inner + 1))]}"
                records[$((inner + 1))]="$temporary"
            fi
        done
    done

    : > "$annualFile"
    printf "%s\n" "${records[@]}" >> "$annualFile"
}

# ============================================================
# Function: Display Annual Salary
# ============================================================

# Read and display annual gross and net salary records in a Whiptail window.
displayAnnualSalary() {
    local -a records
    local displayText="" record salesperson annualGross annualNet

    mapfile -t records < "$annualFile"

    for record in "${records[@]}"; do
        IFS='|' read -r salesperson annualGross annualNet <<< "$record"
        displayText+="Name: $salesperson\n"
        displayText+="Annual Gross Salary: £$annualGross\n"
        displayText+="Annual Net Salary: £$annualNet\n"
        displayText+="--------------------------------\n"
    done

    whiptail --title "Annual Salary Results" \
             --scrolltext \
             --msgbox "$displayText" \
             20 70
}

# ============================================================
# MAIN PROGRAM
# ============================================================

: > "$outputFile"
: > "$annualFile"

# ------------------------------------------------------------
# STEP 1: Validate the number of salespersons
# ------------------------------------------------------------

while true; do
    salespersonCount=$(
        whiptail --title "Salesperson Setup" \
                 --inputbox "Enter number of salespersons (3-20):" \
                 10 60 "" \
                 --nocancel \
                 3>&1 1>&2 2>&3
    )

    if [[ "$salespersonCount" =~ ^[0-9]+$ ]] &&
       (( salespersonCount >= 3 && salespersonCount <= 20 )); then
        break
    fi

    whiptail --title "Invalid Input" \
             --msgbox "Please enter a whole number between 3 and 20." \
             8 50
done

# ------------------------------------------------------------
# STEP 2: Register salesperson names once
# ------------------------------------------------------------

enterSalespersonNames
displaySalespersonList

# ------------------------------------------------------------
# STEP 3: Collect monthly sales for every salesperson
# ------------------------------------------------------------

for (( currentMonth=0; currentMonth<12; currentMonth++ )); do
    monthIndex="$currentMonth"

    whiptail --title "Monthly Data Entry" \
             --msgbox \
             "Entering sales data for:\n\n${months[$monthIndex]}\n\nThere are $salespersonCount salespersons." \
             10 60

    for (( salespersonIndex=0;
           salespersonIndex<salespersonCount;
           salespersonIndex++ )); do

        salespersonName="${salespersonNames[$salespersonIndex]}"

        selectModels
        writeRecord
    done
done

# ------------------------------------------------------------
# STEP 4: Calculate annual gross and net salaries
# ------------------------------------------------------------

whiptail --title "Processing" \
         --infobox "Calculating annual salaries..." \
         8 50
sleep 1
calculateAnnualSalary

# ------------------------------------------------------------
# STEP 5: Sort annual results alphabetically
# ------------------------------------------------------------

whiptail --title "Processing" \
         --infobox "Sorting annual salaries alphabetically..." \
         8 50
sleep 1
bubbleSortAnnual

# ------------------------------------------------------------
# STEP 6: Display annual salary results
# ------------------------------------------------------------

displayAnnualSalary

# ------------------------------------------------------------
# STEP 7: Confirm completion and output file locations
# ------------------------------------------------------------

whiptail --title "Program Complete" \
         --msgbox \
         "Annual salary calculations have been completed.\n\nMonthly records:\n$outputFile\n\nAnnual results:\n$annualFile" \
         12 65

exit 0