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
# Function: writeRecord
# Writes one salesperson's monthly record to the output file
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
# Calculates bonus from total monthly sales
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
# Calculates net annual salary after tax
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
        # for income above £150,000.

        tax=$(( (50000 - 12500) * 20 / 100 ))
        tax=$(( tax + (150000 - 50000) * 40 / 100 ))

        echo "Warning: No tax rate specified above £150,000." >&2

    fi

    echo $(( annualSalary - tax ))
}


# ============================================================
# Function: calculateAnnualSalary
#
# Takes the names from the first month and searches the
# complete monthly record file for every occurrence of each
# salesperson's name.
#
# The matching monthly salaries are accumulated and then
# passed to netTaxedSalary().
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
    # Read all monthly records
    # --------------------------------------------------------

    mapfile -t records < "$outputFile"


    if (( ${#records[@]} == 0 )); then

        echo "No monthly records found."
        return 1

    fi


    # --------------------------------------------------------
    # Identify the first month
    # --------------------------------------------------------

    IFS='|' read -r firstMonth recordName _ _ _ \
        <<< "${records[0]}"


    # --------------------------------------------------------
    # Extract unique salesperson names from the first month
    # --------------------------------------------------------

    salespeople=()

    for (( recordIndex=0; recordIndex<${#records[@]}; recordIndex++ ))
    do

        IFS='|' read -r recordMonth recordName _ _ _ \
            <<< "${records[$recordIndex]}"


        # First month's records have ended
        if [[ "$recordMonth" != "$firstMonth" ]]; then
            break
        fi


        # Add salesperson only once
        if [[ -z "${knownSalespeople[$recordName]}" ]]; then

            salespeople+=("$recordName")
            knownSalespeople["$recordName"]=1

        fi

    done


    # --------------------------------------------------------
    # Create a fresh annual output file
    # --------------------------------------------------------

    : > "$annualFile"


    # --------------------------------------------------------
    # Process each salesperson
    # --------------------------------------------------------

    for salesperson in "${salespeople[@]}"
    do

        annualGross=0


        # ----------------------------------------------------
        # Search every monthly record for this salesperson
        # ----------------------------------------------------

        for (( matchIndex=0; matchIndex<${#records[@]}; matchIndex++ ))
        do

            IFS='|' read -r recordMonth recordName _ _ recordSalary \
                <<< "${records[$matchIndex]}"


            if [[ "$salesperson" == "$recordName" ]]; then

                (( annualGross += recordSalary ))

            fi

        done


        # ----------------------------------------------------
        # Calculate annual net salary
        # ----------------------------------------------------

        annualNet=$(netTaxedSalary "$annualGross")


        # ----------------------------------------------------
        # Save annual result
        #
        # name | annual gross | annual net
        # ----------------------------------------------------

        printf "%s|%d|%d\n" \
            "$salesperson" \
            "$annualGross" \
            "$annualNet" >> "$annualFile"

    done


    echo "Annual salary data saved to $annualFile"
}


# ============================================================
# Function: bubbleSortAnnual
# Sorts annual salary records alphabetically by salesperson
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
    # Rewrite sorted records
    # --------------------------------------------------------

    : > "$annualFile"

    for record in "${records[@]}"
    do
        echo "$record" >> "$annualFile"
    done
}


# ============================================================
# Function: displayAnnualSalary
# Displays name, gross annual salary and net annual salary
# ============================================================

displayAnnualSalary(){

    local record
    local salesperson
    local annualGross
    local annualNet


    echo
    echo "=================================================="
    echo "             ANNUAL SALARY RESULTS"
    echo "=================================================="

    printf "%-25s %-18s %-18s\n" \
        "Salesperson" \
        "Gross Salary" \
        "Net Salary"

    echo "--------------------------------------------------"


    while IFS='|' read -r salesperson annualGross annualNet
    do

        printf "%-25s £%-17d £%-17d\n" \
            "$salesperson" \
            "$annualGross" \
            "$annualNet"

    done < "$annualFile"


    echo "=================================================="
}


# ============================================================
# Main Section
# ============================================================

if [[ ! -f "$outputFile" ]]; then

    touch "$outputFile"

    echo "$outputFile created."

else

    echo "$outputFile already exists."

fi


# Start with a clean monthly data file
: > "$outputFile"


# ============================================================
# Number of Salespersons
# ============================================================

while true
do

    read -r -p "Enter number of salespersons (3-20): " salespersonCount


    if [[ "$salespersonCount" =~ ^[0-9]+$ ]] &&
       (( salespersonCount >= 3 && salespersonCount <= 20 )); then

        break

    fi


    echo "Invalid input. Enter a number between 3 and 20."

done


# ============================================================
# Enter Salesperson Data
# ============================================================

for (( personIndex=1; personIndex<=salespersonCount; personIndex++ ))
do

    echo
    echo "=============================================="
    echo "Salesperson $personIndex"
    echo "=============================================="


    # --------------------------------------------------------
    # Month
    # --------------------------------------------------------

    while true
    do

        read -r -p "Enter month: " monthInput


        case "$monthInput" in

            [Jj]anuary)
                monthIndex=0
                break
                ;;

            [Ff]ebruary)
                monthIndex=1
                break
                ;;

            [Mm]arch)
                monthIndex=2
                break
                ;;

            [Aa]pril)
                monthIndex=3
                break
                ;;

            [Mm]ay)
                monthIndex=4
                break
                ;;

            [Jj]une)
                monthIndex=5
                break
                ;;

            [Jj]uly)
                monthIndex=6
                break
                ;;

            [Aa]ugust)
                monthIndex=7
                break
                ;;

            [Ss]eptember)
                monthIndex=8
                break
                ;;

            [Oo]ctober)
                monthIndex=9
                break
                ;;

            [Nn]ovember)
                monthIndex=10
                break
                ;;

            [Dd]ecember)
                monthIndex=11
                break
                ;;

            *)
                echo "Invalid month."
                ;;

        esac

    done


    # --------------------------------------------------------
    # Salesperson Name
    # --------------------------------------------------------

    while true
    do

        read -r -p "Enter salesperson name: " salespersonName


        if [[ "$salespersonName" =~ ^[A-Za-z][A-Za-z\ \'-]*$ ]]; then

            break

        fi


        echo "Invalid name. Please use letters, spaces, apostrophes or hyphens."

    done


    # --------------------------------------------------------
    # Models Sold
    # --------------------------------------------------------

    modelsSold=()
    modelCount=0


    echo
    echo "Available models:"
    echo "  A class"
    echo "  B class"
    echo "  C class"
    echo "  E class"
    echo "  AMG C65"
    echo
    echo "Enter N when finished."


    while true
    do

        read -r -p "Enter model sold: " modelInput


        if [[ "$modelInput" =~ ^[Nn]$ ]]; then

            if (( modelCount == 0 )); then

                echo "At least one model must be entered."
                continue

            fi

            break

        fi


        case "$modelInput" in

            [Aa]" "[Cc]lass)
                modelsSold[$modelCount]="A class"
                ;;

            [Bb]" "[Cc]lass)
                modelsSold[$modelCount]="B class"
                ;;

            [Cc]" "[Cc]lass)
                modelsSold[$modelCount]="C class"
                ;;

            [Ee]" "[Cc]lass)
                modelsSold[$modelCount]="E class"
                ;;

            [Aa][Mm][Gg]" "[Cc]65)
                modelsSold[$modelCount]="AMG C65"
                ;;

            *)
                echo "Invalid model."
                continue
                ;;

        esac


        (( modelCount++ ))

    done


    # --------------------------------------------------------
    # Save this salesperson's monthly record
    # --------------------------------------------------------

    writeRecord

done


# ============================================================
# Annual Salary Calculation
# ============================================================

calculateAnnualSalary


# ============================================================
# Bubble Sort
# ============================================================

bubbleSortAnnual


# ============================================================
# Display Final Results
# ============================================================

displayAnnualSalary