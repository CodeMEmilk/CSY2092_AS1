Add whiptail and error handling to this program

#Global variable declaration 

# "cm" for centimeter, "in" for inch
inputFlag="cm"

# "m2" for meter square, "in2" for inch square
outputFlag="m2"

breakFlag="false"

length=0
breadth=0

inputPrompt(){
	local choice="$1"
	if [[ "$choice"=~^[in]$ ]]; then
		echo -e "Chose inch\n"
		inputFlag="in"

		read -p -e "Enter value for length:\n" length
		read -p -e "Enter value for breadth:\n" breadth

	elif [[ "$choice"=~^[cm]$ ]]; then
		echo -e "Chose Centi\n"
		inputFlag="cm"

		read -p -e "Enter value for length:\n" length
		read -p -e "Enter value for breadth:\n" breadth
	fi


}

#Validates user inputs 
validation(){

	#Check if values are zero
	if [[ "$length" == 0 || "$breadth" == 0 ]]; then
		return 1
	fi
	
	#Only takes integers and whole numbers
        if [[ "$length"=~^[0-9]+([.][0-9]+)?$ && "$breadth"=~^[0-9]+([.][0-9]+)?$ ]]; then
                # True
		return 0
        else  
                # False
		return 1
        fi
}

#The following code involves conversion logics for displaying the proper units of the output
conversion(){
	local inputFlag="$1"
	local outputFlag="$2"
	mult=$((length*breadth))
	
	if [[ "$inputFlag" == "cm" && "$outputFlag" == "m2" ]]; then
		echo "Cm2 to M2"
		echo $((mult/10000))
		
		
	elif [[ "$inputFlag" == "cm"&& "$outputFlag" == "in2" ]]; then
		echo "Centi to inchs^2"
		echo $((mult*0.0015500031))
		
	elif [[ "$inputFlag" == "in" && "$outputFlag" == "m2" ]]; then
		echo "inch to meter^2"
		echo $((mult*0.00064516))
		
	elif [[ "$inputFlag" == "in" && "$outputFlag" =="in2" ]]; then
		echo "inch to inch^2"
		echo $mult
		
	else
		echo "Error occured"
		return 1 
	fi
}

#The following code prompts user to  select output type
#Does this need a loop to prevent breaking from the whiptail?
promptOutput(){
	read -p "Ouput in m^2 or in in^2" output
	if [[ "$output" =~ ^[mM]$ ]]; then
		outputFlag="m2"
	elif [[ "$output" =~ ^[iI]$ ]]; then
		outputFlag="in2"
	else
		echo "invalid output"
		return 1
	fi
}

#Code responsible for restarting or exiting the program entierly
restart(){
	read -p "Cancel or re-enter inputs" tempC
	if [[ "$tempC" == "restart" ]]; then
		breakFlag="false"
	elif [[ "$tempC" = "quit" ]]; then
		breakFlag="true"
	else 
		echo "error"
		return 1
	fi
}

while [ "$breakFlag" != "true" ]
do
	read -p "Please choose value inputs in either inchs and centimeters" choice
	inputPrompt "$choice"
	if ! validation ; then
		echo "Invalid Inputs"
		continue
	fi
	
	if ! propmtOutput; then
		echo "Invalid output selection"
		continue
	fi
	
	area=$(conversion "$inputFlag" "$outputFlag")
	echo "$area"
	
	restart
done 