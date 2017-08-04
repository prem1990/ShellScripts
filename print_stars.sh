#!/bin/bash
#==============================================#
#Instructions
#Save the file(x.sh) on your Unix or Linux Box
#run chmod 755 x.sh --- This will give executable permissions.
#run the script ---- ./x.sh -n<Number>
#Example: if n=5
# *****
# ****
# ***
# **
# *
# **
# ***
# ****
# *****
#===============================================#



usage_message="$(echo -e "USAGE: $(basename $(readlink -f $0)) -n\n  -n <Input Number>\n")"
[[ -z "$(echo "$@"|grep "\-n")" ]] && clear && echo -e "\n${usage_message}\n" && exit 1

unset number

while getopts ":n:" opt
do
  case "${opt}" in
	n) export number="${OPTARG}" ;;
	#\?) echo "Invalid option: -$OPTARG" >&2 ; exit 1 ;;
    #:) echo "Option -$OPTARG requires an argument." >&2 ; exit 2 ;;
  esac
done


printstars()
{
var="$(echo ${1})"
while [ $var -gt 0 ]
do
   echo -n "*"
   var=$(($var-1))
done
echo -e "\n"
}

Main()
{
for ((i=number;i>0;i--))
do
printstars $i
 if [[ $i -eq 1 ]]; then
	for ((j=2;j<=number;j++))
	do
	   printstars $j
	done
 fi
done
}

Main | awk '!/^$/'
