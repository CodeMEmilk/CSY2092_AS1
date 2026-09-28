# ============================================================
# Variable and Array declaration
# ============================================================

filename="Outputs.txt"

declare -A models=(
    ["A class"]=31095
    ["B class"]=33162
    ["C class"]=42537
    ["E class"]=54437
    ["AMG C65"]=79660
)

declare -a models_sold
declare -a month=(
    January February March April May June
    July August September October November December
)

sales_person_name=""
month_counter=0
model_counter=0

# ============================================================
# Function: writeFile
# Writes one salesperson's record to the output file
# ============================================================

writeFile(){

    local totalSales
    totalSales=0

    for model in "${models_sold[@]}"
    do
        (( totalSales += models[$model] ))
    done

    local bonus
    bonus=$(monthlySalary)

    local monthlySalaryValue
    monthlySalaryValue=$(( 2000 + bonus ))

    local annualSalaryValue
    annualSalaryValue=$(( monthlySalaryValue * 12 ))

    local netSalary
    netSalary=$(netTaxedSalary "$annualSalaryValue")

    printf "%s|%s|%s|%d|%d|%d\n" \
        "${month[$month_counter]}" \
        "$sales_person_name" \
        "$(IFS=','; echo "${models_sold[*]}")" \
        "$totalSales" \
        "$monthlySalaryValue" \
        "$netSalary" >> "$filename"
}

# ============================================================
# Function: displaySalary
# Displays name and associated net salary
# ============================================================

displaySalary(){

    echo
    echo "=============================================="
    echo "        SALES PERSON SALARY RESULTS"
    echo "=============================================="
    printf "%-25s %-15s %-15s\n" \
        "Name" "Monthly Salary" "Net Annual Salary"
    echo "----------------------------------------------"

    local line
    local monthS
    local nameS
    local soldModelsS
    local totalSalesS
    local salaryS
    local netTaxedSalaryS

    while IFS='|' read -r \
        monthS \
        nameS \
        soldModelsS \
        totalSalesS \
        salaryS \
        netTaxedSalaryS
    do

        printf "%-25s £%-14s £%-14s\n" \
            "$nameS" \
            "$salaryS" \
            "$netTaxedSalaryS"

    done < "$filename"

    echo "=============================================="
}

# ============================================================
# Function: monthlySalary
# Calculates bonus based on total monthly sales
# ============================================================

monthlySalary(){

    local totalSales=0
    local monthlyBonus=0

    for model in "${models_sold[@]}"
    do
        (( totalSales += models[$model] ))
    done

    if (( totalSales >= 200000 && totalSales < 300000 )); then

        monthlyBonus=10000

    elif (( totalSales >= 300000 && totalSales < 400000 )); then

        monthlyBonus=15000

    elif (( totalSales >= 400000 && totalSales < 500000 )); then

        monthlyBonus=20000

    elif (( totalSales >= 500000 && totalSales < 650000 )); then

        monthlyBonus=25000

    elif (( totalSales >= 650000 )); then

        monthlyBonus=30000

    else

        monthlyBonus=0

    fi

    echo "$monthlyBonus"
}

# ============================================================
# Function: netTaxedSalary
# Calculates annual tax using the supplied tax bands
# ============================================================

netTaxedSalary(){

    local annualSalary="$1"
    local tax=0
    local taxableBasic=0
    local taxableHigher=0

    # Personal allowance
    if (( annualSalary <= 12500 )); then

        tax=0

    # Basic-rate band
    elif (( annualSalary <= 50000 )); then

        taxableBasic=$(( annualSalary - 12500 ))
        tax=$(( taxableBasic * 20 / 100 ))

    # Higher-rate band
    elif (( annualSalary <= 150000 )); then

        taxableBasic=$(( 50000 - 12500 ))
        taxableHigher=$(( annualSalary - 50000 ))

        tax=$(( taxableBasic * 20 / 100 ))
        tax=$(( tax + taxableHigher * 40 / 100 ))

    else

        # The assignment does not specify a tax rate above £150,000.
        # Therefore only the supplied £12,500-£150,000 bands are used.

        taxableBasic=$(( 50000 - 12500 ))
        taxableHigher=$(( 150000 - 50000 ))

        tax=$(( taxableBasic * 20 / 100 ))
        tax=$(( tax + taxableHigher * 40 / 100 ))

        echo "Warning: Tax rate above £150,000 is not specified in the assignment." >&2

    fi

    echo $(( annualSalary - tax ))
}

# ============================================================
# Function: annualSalary
# Calculates annual salary for a salesperson
# ============================================================

annualSalary(){

    local targetName="$1"
    local annualTotal=0

    local monthS
    local nameS
    local soldModelsS
    local totalSalesS
    local salaryS
    local netTaxedSalaryS

    while IFS='|' read -r \
        monthS \
        nameS \
        soldModelsS \
        totalSalesS \
        salaryS \
        netTaxedSalaryS
    do

        if [[ "$nameS" == "$targetName" ]]; then
            (( annualTotal += salaryS ))
        fi

    done < "$filename"

    echo "$annualTotal"
}

# ============================================================
# Main Section
# ============================================================

if [[ ! -f "$filename" ]]; then

    touch "$filename"

    echo "$filename created."

else

    echo "$filename already exists."

fi

# Clear previous data for this run
> "$filename"

# ============================================================
# Number of Salespersons
# ============================================================

local_dummy=""

while true
do

    read -r -p "Enter number of salespersons (3-20): " salespersonCount

    if [[ "$salespersonCount" =~ ^[0-9]+$ ]] &&
       (( salespersonCount >= 3 && salespersonCount <= 20 )); then

        break

    else

        echo "Invalid input. Please enter a number between 3 and 20."

    fi

done

# ============================================================
# Enter salesperson data
# ============================================================

for (( person=1; person<=salespersonCount; person++ ))
do

    echo
    echo "=============================================="
    echo "Entering details for salesperson $person"
    echo "=============================================="

    # --------------------------------------------------------
    # Month
    # --------------------------------------------------------

    while true
    do

        read -r -p "Enter month: " monthInput

        if [[ "$monthInput" =~ ^[Jj]anuary$ ]]; then
            month_counter=0
            break

        elif [[ "$monthInput" =~ ^[Ff]ebruary$ ]]; then
            month_counter=1
            break

        elif [[ "$monthInput" =~ ^[Mm]arch$ ]]; then
            month_counter=2
            break

        elif [[ "$monthInput" =~ ^[Aa]pril$ ]]; then
            month_counter=3
            break

        elif [[ "$monthInput" =~ ^[Mm]ay$ ]]; then
            month_counter=4
            break

        elif [[ "$monthInput" =~ ^[Jj]une$ ]]; then
            month_counter=5
            break

        elif [[ "$monthInput" =~ ^[Jj]uly$ ]]; then
            month_counter=6
            break

        elif [[ "$monthInput" =~ ^[Aa]ugust$ ]]; then
            month_counter=7
            break

        elif [[ "$monthInput" =~ ^[Ss]eptember$ ]]; then
            month_counter=8
            break

        elif [[ "$monthInput" =~ ^[Oo]ctober$ ]]; then
            month_counter=9
            break

        elif [[ "$monthInput" =~ ^[Nn]ovember$ ]]; then
            month_counter=10
            break

        elif [[ "$monthInput" =~ ^[Dd]ecember$ ]]; then
            month_counter=11
            break

        else

            echo "Invalid month. Please enter a valid month."

        fi

    done

    # --------------------------------------------------------
    # Salesperson name
    # --------------------------------------------------------

    while true
    do

        read -r -p "Enter salesperson name: " sales_person_name

        if [[ "$sales_person_name" =~ ^[A-Za-z][A-Za-z[:space:]\'-]*$ ]]; then
            break
        else
            echo "Invalid name. Please use alphabetic characters only."
        fi

    done

    # --------------------------------------------------------
    # Models sold
    # --------------------------------------------------------

    models_sold=()
    model_counter=0

    echo
    echo "Available models:"
    echo "A class"
    echo "B class"
    echo "C class"
    echo "E class"
    echo "AMG C65"
    echo
    echo "Enter N when you have finished entering models."

    while true
    do

        read -r -p "Enter model sold: " temp

        # N terminates model entry
        if [[ "$temp" =~ ^[Nn]$ ]]; then

            if (( model_counter == 0 )); then
                echo "At least one model must be entered."
                continue
            fi

            break

        # Regular-expression validation
        elif [[ "$temp" =~ ^(A|a)[[:space:]]+(class|Class)$ ]]; then

            models_sold[$model_counter]="A class"

        elif [[ "$temp" =~ ^(B|b)[[:space:]]+(class|Class)$ ]]; then

            models_sold[$model_counter]="B class"

        elif [[ "$temp" =~ ^(C|c)[[:space:]]+(class|Class)$ ]]; then

            models_sold[$model_counter]="C class"

        elif [[ "$temp" =~ ^(E|e)[[:space:]]+(class|Class)$ ]]; then

            models_sold[$model_counter]="E class"

        elif [[ "$temp" =~ ^(AMG|amg)[[:space:]]+(C65|c65)$ ]]; then

            models_sold[$model_counter]="AMG C65"

        else

            echo "Invalid model. Please enter one of the listed models."
            continue

        fi

        (( model_counter++ ))

    done

    # --------------------------------------------------------
    # Save record
    # --------------------------------------------------------

    writeFile

done

# ============================================================
# Bubble Sort
# ============================================================

mapfile -t people < "$filename"

numberOfRecords="${#people[@]}"

for (( i=0; i<numberOfRecords-1; i++ ))
do

    for (( j=0; j<numberOfRecords-i-1; j++ ))
    do

        IFS='|' read -r monthOne nameOne soldModelsOne \
            totalSalesOne salaryOne netSalaryOne <<< "${people[$j]}"

        IFS='|' read -r monthTwo nameTwo soldModelsTwo \
            totalSalesTwo salaryTwo netSalaryTwo <<< "${people[$((j+1))]}"

        # Alphabetical comparison
        if [[ "$nameOne" > "$nameTwo" ]]; then

            tempRecord="${people[$j]}"
            people[$j]="${people[$((j+1))]}"
            people[$((j+1))]="$tempRecord"

        fi

    done

done

# ============================================================
# Rewrite file after bubble sort
# ============================================================

: > "$filename"

for record in "${people[@]}"
do
    echo "$record" >> "$filename"
done

# ============================================================
# Display results
# ============================================================

displaySalary

echo
echo "Data has been saved to: $filename"