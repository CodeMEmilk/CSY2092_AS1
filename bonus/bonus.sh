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
