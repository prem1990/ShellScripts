#/bin/bash

#===================================================================
# static variables
#===================================================================
parentPath=$(pwd)
settings="${parentPath}/settings.txt"
number_tag=$(grep -i "Number" "${settings}"|cut -d":" -f2)
type_tag=$(grep -i "Type" "${settings}"|cut -d":" -f2)
number_of_threads=$(grep -i "Threads" "${settings}"|cut -d":" -f2)
url_file=$(grep -i "Urlfile" "${settings}"|cut -d":" -f2)
process_url_file="${parentPath}/${url_file}"
future_date=$(date -v+"${number_tag}"d +%Y%m%d%H%M)
future_hours=$(date -v+"${number_tag}"H +%Y%m%d%H%M)
future_minutes=$(date -v+"${number_tag}"M +%Y%m%d%H%M)
temp=0


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
export TERM=xterm
#export TZ=America/Chicago
print_header "mac_stress_test.sh launched at $(date +%c)"
}

#===================================================================
cleanup()
#===================================================================
{
sleep 20
print_header "mac_stress_test.sh finished at $(date +%c)"
}

#===================================================================
time_intervel_check()
#===================================================================
{
if [[ "${type_tag}" == "days" ]]; then
	while [ "${future_date}" -gt $(date +%Y%m%d%H%M) ]
		do
			sleep 1
			send_curl_commands			
		done
elif [[ "${type_tag}" == "hours" ]]; then
	while [ "${future_hours}" -gt $(date +%Y%m%d%H%M) ]
		do
			sleep 1
			send_curl_commands
		done
else	
	while [ "${future_minutes}" -gt $(date +%Y%m%d%H%M) ]
	do
			sleep 1
			send_curl_commands
	done
fi
}

#===================================================================
send_curl_commands()
#===================================================================
{
		for singlesite in $(cat "${process_url_file//[[:cntrl:]]/}")
			do
			  if [[ -n $(echo "${singlesite//[[:cntrl:]]/}"|grep "http:") ]]; then
				output=$(curl --silent "${singlesite//[[:cntrl:]]/}") 
				sleep 2
				#if [[ -n "${output}" ]]; then
					#echo -e "${singlesite//[[:cntrl:]]/}: True"
				#else
					#echo -e "${singlesite//[[:cntrl:]]/}: False"
				#fi
			else 
				output=$(curl --silent -k -x 127.0.0.1:8888 "${singlesite//[[:cntrl:]]/}") 
				sleep 2
				#if [[ -n "${output}" ]]; then
					#echo -e "${singlesite//[[:cntrl:]]/}: True"
				#else
					#echo -e "${singlesite//[[:cntrl:]]/}: False"
				#fi
			fi
		done
time_intervel_check
}


#===================================================================
main_function()
#===================================================================
{
while [ ${temp} -lt ${number_of_threads} ]
do
send_curl_commands &
export temp=$(($temp+1))
done
echo "Threads Creation Done"
}


#===================================================================
check_curls()
#===================================================================
{
while true;
do
curl_count=$(ps -fed | grep curl| grep -v "grep curl" |wc -l)
if [[ "${curl_count}" -gt 0  ]]; then
      sleep 10
else
	return 0
fi
done
}
#===================================================================
# the actual script
#===================================================================
prepare_environment
main_function
echo "Waiting for Threads to Finish Jobs"
wait $!
check_curls
cleanup
