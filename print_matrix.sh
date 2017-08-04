#!/bin/bash
#==============================================#
#Instructions
#Save the file(x.sh) on your Unix or Linux Box
#run chmod 755 x.sh --- This will give executable permissions.
# ./print_matrix.sh -r11 -c12 -dn
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# |*|.|*|.|*|.|*|.|*|.|*|
# (OR)
# ./print_matrix.sh -r11 -c12 -dy
# |*|.|.|.|.|.|.|.|.|.|*|
# |.|*|.|.|.|.|.|.|.|*|.|
# |.|.|*|.|.|.|.|.|*|.|.|
# |.|.|.|*|.|.|.|*|.|.|.|
# |.|.|.|.|*|.|*|.|.|.|.|
# |.|.|.|.|.|*|.|.|.|.|.|
# |.|.|.|.|*|.|*|.|.|.|.|
# |.|.|.|*|.|.|.|*|.|.|.|
# |.|.|*|.|.|.|.|.|*|.|.|
# |.|*|.|.|.|.|.|.|.|*|.|
# |*|.|.|.|.|.|.|.|.|.|*|
#(OR)
# ./print_matrix.sh -r11 -c12
# |*|.|.|.|.|.|.|.|.|.|*|
# |.|*|.|.|.|.|.|.|.|*|.|
# |.|.|*|.|.|.|.|.|*|.|.|
# |.|.|.|*|.|.|.|*|.|.|.|
# |.|.|.|.|*|.|*|.|.|.|.|
# |.|.|.|.|.|*|.|.|.|.|.|
# |.|.|.|.|*|.|*|.|.|.|.|
# |.|.|.|*|.|.|.|*|.|.|.|
# |.|.|*|.|.|.|.|.|*|.|.|
# |.|*|.|.|.|.|.|.|.|*|.|
# |*|.|.|.|.|.|.|.|.|.|*|
#===============================================#

usage_message="$(echo -e "USAGE: $(basename $(readlink -f $0)) -r -c -d\n -r <Number of Rows>\n -c <Number of Columns>\n -d <default Matrix: y or n>\n")"
[[ -z "$(echo "$@"|grep "\-c")" || -z "$(echo "$@"|grep "\-r")" ]] && clear && echo -e "\n${usage_message}\n" && exit 1

unset rows 
unset columns
unset default

while getopts ":r:c:d:" opt
do
  case "${opt}" in
	r) export rows="${OPTARG}" ;;
	c) export columns="${OPTARG}" ;;
	d) export default="${OPTARG}" ;;
	\?) echo "Invalid option: -$OPTARG" >&2 ; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2 ; exit 2 ;;
  esac
done


Draw()
{
var="$(echo ${1})"
output=""
while [ $var -gt 1 ]
do
   output+=$(echo -n "|.")
   var=$(($var-1))
   if [[ $var -eq "1" ]]; then
   output+=$(echo -n "|")
   fi
done
}

Main()
{
difference=$(($columns - $rows))
if (( $difference == 1 && $columns % 2 == 0 && $rows % 2 != 0 ))
then
	count=0
	if [[ "${default}" = "y" || "${default}" = "" ]];then 
		Draw $columns 
			for ((i=$rows;i>0;i--))
			do
				count=$(($count+1))
				if [[ $i -eq $count ]];then
					echo "${output}" | sed "s/\./*/${count}"
					echo -e "\n"
					count=$(($count-1))
				else
					echo "${output}" |sed "s/\./*/${i};s/\./*/${count}"
					echo -e "\n"
				fi
			done
	else
		export sedCommandBuild=""
		Draw $columns
		while [ $count -ne $(($columns / 2)) ]
		do
			count=$(($count+1))
			sedCommandBuild+=$(echo "s/\\./*/${count};")
		done
		updatedsedCommandBuild=$(echo $sedCommandBuild|sed 's/.$//')
			for ((i=$rows;i>0;i--))
			do
				echo "${output}" |sed "${updatedsedCommandBuild}"
				echo -e "\n"
			done
	fi
else
	echo -e "Row should be Odd Number"
	echo -e "AND"
	echo -e "Column should Even Number"
	echo -e "AND"
	echo -e "Differnce between Column and Row should be equal to 1"
fi
}

Main |  awk '!/^$/'
