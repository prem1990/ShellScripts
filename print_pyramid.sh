#!/bin/bash
#==============================================#
#Instructions
#Save the file(x.sh) on your Unix or Linux Box
#run chmod 755 x.sh --- This will give executable permissions.
#run the script ---- ./x.sh -n<Number>
#Example: if n=10
          # a
         # a b
        # a b c
       # a b c d
      # a b c d e
     # a b c d e f
    # a b c d e f g
   # a b c d e f g h
  # a b c d e f g h i
 # a b c d e f g h i j
 # a b c d e f g h i j
  # a b c d e f g h i
   # a b c d e f g h
    # a b c d e f g
     # a b c d e f
      # a b c d e
       # a b c d
        # a b c
         # a b
          # a

#===============================================#

usage_message="$(echo -e "USAGE: $(basename $(readlink -f $0)) -n\n  -n <Print Diamond for N characters>\n")"
message="$(echo "number cannot be greater than 26 because alphabets are 26 only")"
[[ -z "$(echo "$@"|grep "\-n")" ]] && clear && echo -e "\n${usage_message}\n" && exit 1

unset number

while getopts ":n:" opt
do
  case "${opt}" in
	n) export number="${OPTARG}" ;;
	\?) echo "Invalid option: -$OPTARG" >&2 ; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2 ; exit 2 ;;
  esac
done

if [[ $number -gt 26 ]]; then
echo -e "\n${message}\n" 
exit 1
fi

original="abcdefghijklmnopqrstuvwxyz"
var="${original:0:$number}"
length="${#var}"
length1="${#var}"


printSpace()
{
var1="$(echo ${1})"
while [ $var1 -gt 0 ]
do
   echo -n " "
   var1=$(($var1-1))
done
}

Main()
{
for ((j=1;j<=length;j++))
do
printSpace $length1
echo "${var:0:j}"|sed 's/./& /g'
length1=$(($length1-1))
if [[ $length1 -eq 0 ]]; then
    length1=1
 for ((k=length;k>0;k--))
  do
        printSpace $length1
		echo "${var:0:k}"|sed 's/./& /g'
		length1=$(($length1+1))
  done
fi
done
}

Main
