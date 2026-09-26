# Variable and Array declaration 
filename="Outputs.txt"
break="false"
stop="false"
declare -A models=([A class]=31095 [B class]=33162 [C class]=42537 [E class]=54437 [AMG C65]=79660 )

declare -a models_sold
sales_person_name=""

declare -A month=(January, February, March, April, May, June, July, August, September,October, November, December)

month_counter=1
# Functions
writeFile(){
    while read -r line
	do 
		printf "%s,%s" "$month" "$sales_person_name" >> students.txt
		for model in "${models_sold[@]}"
		do 
			printf "%s" "$model" >> students.txt
		done
			
		printf "/n"
	done
} 

# The following code displays only the necessary outputs from the file

displaySalary(){
    mapfile -t salaryRecord < student.txt
    while read -r line 
    do
        record= "${salaryRecord["$counter"]}"

        read -r monthS nameS soldModelsS salaryS netTaxedSalaryS <<< "$record"

        printf "$s $d $d"  "$nameS" "$salaryS" "$netTaxedSalaryS" 
        printf "/n"
    done
}

# The following calculates the monthly salary of salesperson from their total monthly Sales
monthlySalary(){
	monthlySalary=0
	totalSales=0
	for model in "${models_sold[@]}"
	do 
		case "$model" in 
		"A class") totalSales+=31095;;
		"B class") totalSales+=33162;;
		"C class") totalSales+=42537;;
		"E class") totalSales+=54437;;
		"AMG C65") totalSales+=79660;;
		esac
	done
	case true in
	$( [[ $totalSales >= 200000 && $totalSales < 300000 ]] && echo true )) monthlySalary+=10000;;
	$( [[ $totalSales >= 300000 && $totalSales < 400000 ]] && echo true )) monthlySalary+=15000;;
	$( [[ $totalSales >= 400000 && $totalSales < 500000 ]] && echo true )) monthlySalary+=20000;;
	$( [[ $totalSales >= 500000 && $totalSales < 650000 ]] && echo true )) monthlySalary+=25000;;
	$( [[ $totalSales >= 650000 ]] && echo true )) monthlySalary+=30000;;
	*) echo "No monthlySalary"
	
	esac
	echo "$monthlySalary"
}

# The following function calculates the net salary after tax
netTaxedSalary(){
	tax=0
	local annualSalary="$1"

	case true in 
	$( [[ $annualSalary <= 12500 ]] && echo true )) tax=0;;
	$( [[ $annualSalary > 12500 && $annualSalary <= 50000 ]] && echo true )) tax=$(annualSalary*0.2);;
	$( [[ $annualSalary > 50000 && $annualSalary < 150000 ]] && echo true )) tax=$(annualSalary*0.4);;
	*) echo "No annualSalary"
	esac
	taxedSalary=$(annualSalary-tax);
	echo "$taxedSalary"
}

# The following is my favorite solution 
annualSalary(){
	count1=0
	count2=0
	accuSalary=0
	mapfile -t salaryLine < student.txt 
	while read -r 
	do 
		record="${salaryLine["$count1"]}"
		count1=$count2

		read -r monthS nameS soldModelsS salaryS <<< "$record"

		while read -r 
		do
			recordCom="${salaryLine["$count2"]}"
			read -r monthSS nameSS soldModelsSS salarySS <<< "$recordCom"

			if [[ "$nameS" == "$namess" ]]; then
				accuSalary+="$salarySS"
			fi
			count2+=1
		done
		count2=$count1
		count1+=1
	done
	# Now I just need to find a way to append this value to the file itself at each line.
	echo "$accuSalary"
}


# Main section
if [ ! -f "$filename" ]; then
	touch "$filename"
	echo "Output.txt File exists now"
else 
	echo "Output.txt File exists"
fi

echo "Entering data to file"

while [ ! "$break" ] 
do  	
	printf "Month is %s: " "$month[model_counter]" 
	echo -e "/n Enter Sales person name: " sales_person_name
	
	while [ ! "$stop" ]
	do 	
		model_counter=0
		echo -e "Please enter N to stop entering models"
		echo -e "Enter model sold" temp
		if [[ "$temp" =~ [nN] ]]; then
			break 
		elif [[ -n "${models[$temp]}" ]]; then
			models_sold[model_counter]="$temp"
		else
			echo "Invalid input, skipping"
			stop="True"
		fi
		
        writeFile()

		model_counter+=1
	done
	
done


# The following is for bubble sorting 
count=0

mapfile -t people < student.txt

#The following needs to be incased in another loop for actual bubble sort 
#The file will be sorted so no need to re-enter within the file 
while read -r 
do 
    recordOne="${people["$count"]}"
    recordTwo="${people["$count"+1]}"
    read -r monthOne nameOne soldModelsOne <<<"$recordOne"
    read -r monthTwo nameTwo soldModelsTwo <<<"$recordTwo"

    # The following is supposed to rearrange based on alphabetical order
    # Currently it is not made so
    if ((nameOne > nameTwo)); then
        swap people["$count"] people["$count" +1]

done < students.txt

# For displaying salary

echo displaySalary
