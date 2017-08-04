#/bin/bash

#===================================================================
# usage verification - this MUST be done first
#===================================================================
usage_message="$(echo -e "USAGE: $(basename $(readlink -f $0)) -n -t \n  -n <Number>\n  -t <Type (\"days\", \"hours\", \"minutes\")>\n" )"
[[ -z "$(echo "$@"|tr ' ' '\n'|grep "\-n")" || -z "$(echo "$@"|tr ' ' '\n'|grep "\-t")" ]] && clear && echo -e "\n${usage_message}\n" && exit 1

#===================================================================
# parse the command line - this MUST be done second
#===================================================================

while getopts ":n:t:" opt
do
  case "${opt}" in
	n) export number_tag="${OPTARG}" ;;
	t) export type_tag="${OPTARG}" ;;
	\?) echo "Invalid option: -$OPTARG" >&2 ; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2 ; exit 2 ;;
  esac
done


#===================================================================
print_header()
#===================================================================
{
delimiter="$(for i in $(seq 1 ${#1}); do echo -n "="; done)"
echo -e "${delimiter}\n${1}\n${delimiter}"
}

#===================================================================
prepare_environment()
#===================================================================
{
#export TERM=xterm
#export TZ=America/Chicago
print_header "$(basename $(readlink -f $0)) launched at $(date +%c)"
}

#===================================================================
cleanup()
#===================================================================
{
print_header "$(basename $(readlink -f $0)) finished at $(date +%c)"
}

#===================================================================
main()
#===================================================================
{
if [[ "${type_tag}" == "days" ]]; then
	while [ $(date +%Y%m%d%H%M -d"+$number_tag $type_tag") -gt $(date +%Y%m%d%H%M -d"now") ]
		do
		echo "in days"
		done
elif [["${type_tag}" == "hours" ]]; then
	while [ $(date +%Y%m%d%H%M -d"+$number_tag $type_tag") -gt $(date +%Y%m%d%H%M -d"now") ]
		do
			echo "in hours"
		done
else	
	while [ $(date +%Y%m%d%H%M -d"+$number_tag $type_tag") -gt $(date +%Y%m%d%H%M -d"now") ]
	do
		echo "in minutes"
	done
fi
}

#===================================================================
# the actual script
#===================================================================
prepare_environment
main()
cleanup
