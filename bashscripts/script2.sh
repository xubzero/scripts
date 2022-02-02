#! /bin/bash

# Title: Simple Bash Log Analyzer
# Author: 
# Student Number: 
# Date: 20/01/2022

# ::COLORS

# Setting the colors
WHITE="\033[0m"
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[92m'
BLUE="\033[0;34m"
ERROR="${WHITE}[${RED}-${WHITE}] " 
READLINE="${BLUE}>${WHITE}"
PASS="${WHITE}^${GREEN} "
LIST=" - "
checkErr="${WHITE}[${BLUE}!${WHITE}] "
COLUMNS="${YELLOW}"

# ::CONSTANTS
Mode="off"

# ::FUNCTIONS
# Increments the tally variable for summing up totals
increment() {
	tally=$1
	tally=$(($tally + 1));
}

#  This function does nothing
pass(){
	true
}

# Simple function for preparing the standard.standard may be PROTOCAL,PACKETS,BYTES etc
fetchcolumn() {
	# Where standard is PROTOCOL=`TCP` OR DEST_IP=EXT_SERVER
	standard=$1
	column=`echo ${standard} | awk -F "=" '{print $1}'`
	# Column can be PROTOCOL,PACKETS,BYTES,DEST_IP etc.
	echo $column
}

# Simple function for preparing the value for a standard. This may be TCP (for protocol),EXT_SERVER (for dest ip)
fetchvalue(){
	# Where standard is PROTOCOL=`TCP` OR DEST_IP=EXT_SERVER
	standard=$1
	# Fetching the value from the standard and removing the backticks from the value
	value=`echo ${standard}   | awk -F "=" '{print $2}' | sed s/'\`'/''/g`
	# Value can be TCP,EXT_SERVER etc
	echo $value
}

# This function Deletes a file
delete(){
	touch "${1}"
	rm "${1}" 2>/dev/null
}

# Functions start here
breakpoint(){
	newline
	echo "Hit breakpoint"
	sleep 40000
}

# This function justs prints a new string to the terminal
newline(){
	echo ""
}

# This function checks whether the provided file exists
exists(){
	if [[ -f $FILE ]]; then
		FILE="${1}"
	else
		newline
		echo -e "$ERROR File '$FILE' does not exist  $WHITE"
		echo -e "$ERROR Exitting  $WHITE"
		exit
	fi

}

# ::PREPARATION 
# Specifying the folder to store the generated output files 
outDir="results"

# Creating the output folder in none exists
mkdir -p $outDir 2>/dev/null
newline

# Fetches all csv logfiles
logfiles=`ls *.csv`

while true;do
	# Initializing an empty array
	logfile_array=()

	# Adding each log file to the array
	for logfile in $logfiles;do
		logfile_array+=("$logfile")
	done

	echo "Found ${#logfile_array[@]} Log Files "
	echo "...................."
	newline



	logfile_array+=("All logfiles")
	for index in "${!logfile_array[@]}";do
		echo -e "$index $LIST ${logfile_array[index]}  $WHITE" 
	done
	newline

	echo -e "Press $YELLOW CTRL + C $WHITE to quit $WHITE"
	newline
	# Accepting input from the user 
	echo -e "$READLINE Enter the number of the logfile to analyse :  $WHITE" 
	# EXAMPLE index
	read -p " NUMBER : " index



	if [[ $index =~ [0-9] ]];then
		# echo "Input contains number"
		true
	else
		echo -e "$ERROR Exitting . Input contains non numerical value $WHITE"
		exit
	fi


	# Fetching the file associated with that index from the array
	FILE="${logfile_array[$index]}"

	# Checking whether all log files have been selected
	if [[ "${FILE}" == "All logfiles" ]]
	then
		FILE="*.csv"
		echo -e "$PASS All log files selected  $WHITE"
	else
		echo -e "$PASS One file selected : $yellow ${FILE}  $WHITE"
		exists $FILE
		FILE="${FILE}"
	fi

	newline

	# Writing the results to a file
	echo -e "$READLINE Enter filename to save the results to (eg test.csv):  $WHITE"

	#  demo save file
	# saveFile="checklog.csv"
	read -p "FILE : " saveFile

	if [[ $saveFile == *"csv"* ]]
	then
		true
	else
		saveFile="${saveFile}.csv"
	fi

	# Merging the file to the output directory
	outFile="$outDir/$saveFile"
	# checking whether a similar file exists
	if test -f "$outFile"; then
		echo -e "$ERROR Exitting. $outFile already exists. Choose a unique name $WHITE"
		exit
	fi

	# Making sure the tempFile  and $outFile do not exist (if they exist ,they may interfere with the results)
	tempFile="$outDir/tempFile.txt"
	delete $tempFile 
	delete $outFile
	touch $outFile 2>/dev/null

	echo -e "$PASS Storing output to : $outFile  $WHITE"

	newline
	# This is the Query Bar
	echo -e "$READLINE Enter one or more parameters to Query :  $WHITE"
	echo -e ""
	echo -e "Examples : "
	printf "%-60s%-12s\n" "   PROTOCOL=\`ICMP\`" "-  for one field search" 
	printf "%-60s%-12s\n" "   PROTOCOL=\`TCP\` and SRC IP=\`ext\` and PACKETS > \`10\`" "-  for multiple field search" 
	# printf "%-25s%-12s\n" "	PROTOCOL=\`ICMP\`" "-  for one field search" 
	echo -e ""

	# Example Query
	# Query="SRC IP=\`EXT_SERVER\` and PROTOCOL=\`TCP\` and BYTES > \`10\`"

	# reading the Query 
	read -p "Your Query: " Query
	newline



	if [[ `echo $Query | awk '{print toupper($0)}'` == *"FIND ALL MATCHES WHERE"* ]]
	then
		FILE="*.csv"
		echo -e "$READLINE Searching all files $WHITE"
			# ADVANCED FEATURE
		echo
		echo "ADVANCED : Selecting all logfiles enables the script to run searches on all available server access logs based on one (1) field criteria input, e.g., find all matches where PROTOCOL='\`TCP\` in all available log files"
		echo
		Query=`echo $Query | awk '{print toupper($0)}' | sed s/"FIND ALL MATCHES WHERE "/""/g `
	else
		true
	fi
	# Converting the query to uppercase - Making the query case insensitive
	Query=`echo $Query | awk '{print toupper($0)}' | sed s/" AND "/","/g `


	# Function for fetching columns such as protocal,dest ip,src ip
	QueryStandard (){
		tally=0
		string=""
		RECORDS=`cat $FILE | grep -iv "DATE,DURATION,PROTOCOL," | grep -iv "normal"`
		standardA=$1
		columnNum=$2
		caseSensitive=$3
		column=$(fetchcolumn $standardA)
		value=$(fetchvalue $standardA)

	# Iterating through items in the source file
		while read -r string;
		do  
			# Finding the value and removing spaces
			awk="awk -F \",\" '{print \$$columnNum}'"
			outval=`echo $string | eval $awk | sed s/" "/""/g`

			# Checking whether the search should be case sensitive
			if [[ $caseSensitive == "yes" ]]
			then
				if [[ $outval == "$value" ]]
				then
					echo "${string}" >> $outFile
					increment $tally
				else
					pass # do nothing
				fi
			else
				if [[ $outval == *"$value"* ]]
				then
					echo "${string}" >> $outFile
					increment $tally
				else
					pass # do nothing
				fi
			fi
		done <<< $RECORDS

		newline>$tempFile
		mv $outFile $tempFile 2>/dev/null
		delete $outFile
		FILE=$tempFile # Setting the temporary file as the input file (Using the results from the previous query as the input)
		newline
		echo -e "       $tally records  $WHITE"
		newline
		newline
		tally=0

	}

	# For performing comparisons in packets and bytes
	QueryStandardPackets(){
		tally=0
		string=""
		RECORDS=`cat $FILE | grep -iv "DATE,DURATION,PROTOCOL," | grep -iv "normal"`
		criteria=$1
		columnNum=$2
		caseSensitive=$3
		IFS=' ' read -r -a params <<< "$criteria"
		column=`echo "${params[0]}"| sed s/" "/""/g`
		newline
		operator=`echo "${params[1]}"| sed s/" "/""/g | awk '{ print tolower($0) }' ` 
		value=`echo "${params[2]}" | sed s/'\`'/''/g | sed s/" "/""/g `

		# Fetching the sign to use in the comparison
		if [[ $operator == "<" || $operator == *"-lt"* ]]
		then
			sign="-lt"
		elif [[ $operator == ">" || $operator == *"-gt"* ]]
		then
			sign="-gt"
		elif [[ $operator == "=" || $operator == "-eq" || $operator == "(-eq)" ]]
		then
			sign="-eq"
		elif [[ $operator == "!=" || $operator == *"!(-eq)"* || $operator == "-ne" ]]
		then
			sign="-ne"
		else
			echo -e "$RED Please use a valid operator  $WHITE"
			exit 
		fi

		packetRecords=0
	# Reading the results in the file
		while read -r string;
		do  
			awk="awk -F \",\" '{print \$$columnNum}'"
			# Adding the getting the column value and removing spaces - returns packet value
			outval=`echo $string | eval $awk | sed s/" "/""/g`

			# Building a query based on the user input
			query="$outval $sign $value"
			
			# Running the query
			result=`eval 'test $query && echo pass || echo false' 2>/dev/null`

			# Fetching the results based on logic
			if [[ $caseSensitive == "yes" ]]
			then
				if [[ $result == "pass" ]]
				then
					increment $tally
					echo "${string}" >> $outFile

				else
					pass # this does nothing
				fi
			else
				if [[ $outval == *"$value"* ]]
				then
					increment $tally
					echo "${string}" >> $outFile
				else
					pass # this does nothing
				fi
			fi
		done <<< $RECORDS
		string=""
		newline>$tempFile
		mv $outFile $tempFile 2>/dev/null
		delete $outFile
		FILE=$tempFile
		# echo -e "$BLUE         $column => $tally records found   $WHITE"
		tally=0
	}

	# Parameters can be SRC IP=`EXT_SERVER` or PROTOCOL=`ICMP` or BYTES > `10`
	# Splitting the query into individual parameters
	IFS=',' read -r -a array <<< "$Query"

	# Counting the parameters ()
	params="${#array[@]}"
	newline
	echo -e "$PASS Parameter count : $params  $WHITE"

	# ADVANCED FEATURE
	echo
	echo -e "Advanced Feature : Enable the log tool script to run searches on a single server access log of the user’s choice using both two (2) and three (3) field criteria inputs, e.g. find all matches where PROTOCOL=\`TCP\` and SRC IP=\`ext\` and PACKETS > \`10\`"
	echo

	# Iterating through the array of criterias
	for index in ${!array[@]};do
		criteria="${array[index]}"
		standardA=`echo $criteria | sed s/" "/""/g`
		echo -e "  $COLUMNS $criteria  $WHITE"

		if [[ $standardA == *"PROTOCOL"* ]]
		then
			QueryStandard $standardA 3 no
		elif [[ $standardA == *"SRCIP"* ]]
		then
			QueryStandard $standardA 4 no
		elif [[ $standardA == *"DESTIP"* ]]
		then
			QueryStandard $standardA 6 no
		elif [[ $standardA == *"PACKETS"* ]]
		then
			QueryStandardPackets "${criteria}" 8 yes
		elif [[ $standardA == *"BYTES"* ]]
		then
			QueryStandardPackets "${criteria}" 9 yes
		else
			echo -e "$ERROR Invalid Field Name : $standardA $WHITE"
			exit
		fi
	done

	newline
	newline
	echo "PROTOCOL,SRC IP,DEST IP,PACKETS,BYTES"> $outFile
	cat $tempFile >> $outFile
	delete $tempFile
	echo "PROTOCOL,SRC IP,DEST IP,PACKETS,BYTES"> $tempFile


	columnOutput(){
		string=$1
		protocol=`echo $string | awk -F "," '{print $3}'`
		src_ip=`echo $string | awk -F "," '{print $4}'`
		dest_ip=`echo $string | awk -F "," '{print $6}'`
		packets=`echo $string | awk -F "," '{print $8}'`
		bytes=`echo $string | awk -F "," '{print $9}'`
		printf "%-12s%-12s%-12s%-12s%-12s\n" "$protocol" "$src_ip" "$dest_ip" "$packets" "$bytes"
		echo "$protocol,$src_ip,$dest_ip,$packets,$bytes" >> $tempFile
	}

	echo -e "$PASS Printing Results $WHITE"
	newline
	tally=0
	while read -r string;
	do
		increment $tally
		columnOutput "${string}"
	done <<< `cat $outFile | grep -iv "PACKETS" || newline `
	newline 
	tally=$(($tally - 1));
	# echo -e "$YELLOW $tally results.  $WHITE"
	newline 
	newline 
	delete $outFile
	mv $tempFile $outFile
	echo -e "$PASS Results written to $YELLOW $outFile  $WHITE"

	newline
	newline
done