usage_message="$(echo -e "USAGE: $(basename $(readlink -f $0)) -u -s -r\n  -u <Text file for URL's>\n -s <Settings)>\n -r <Repeat Tasks)>\n")"
[[ -z "$(echo "$@"|grep "\-u")" || -z "$(echo "$@"|grep "\-s")" || -z "$(echo "$@"|grep "\-r")" ]] && echo -e "\n${usage_message}\n" && exit 1

unset url_file && unset settings_from_file && unset repeat_task

while getopts ":u:s:r:" opt

do
  case "${opt}" in
	u) export url_file="${OPTARG}" ;;
	s) export settings_from_file="${OPTARG}" ;;
	r) export repeat_task="${OPTARG}" ;;
	\?) echo "Invalid option: -$OPTARG" >&2 ; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2 ; exit 2 ;;
  esac
done


#===================================================================
# static variables
#===================================================================
process_url_file="$(dirname $(readlink -f $0))/${url_file}"
main_function_pid_list="$(dirname $(readlink -f $0))/stress_test_csproxy_outputs/main_function_pid_list.txt"
send_curl_commands_pid_list="$(dirname $(readlink -f $0))/stress_test_csproxy_outputs/send_curl_commands_pid_list.txt"
terminal_output="$(dirname $(readlink -f $0))/stress_test_csproxy_outputs/terminal_output.txt"
stress_test_output_directory="$(dirname $(readlink -f $0))/stress_test_csproxy_outputs"
number_of_threads="$(cat $(dirname $(readlink -f $0))/${settings_from_file}|grep -i "Threads"|sed 's/Threads://g')"
ip_of_rkm="$(cat $(dirname $(readlink -f $0))/${settings_from_file}|grep -i "rkm_ip"|sed 's/rkm_ip://g')"
#===================================================================
prepare_environment()
#===================================================================
{
export TERM=xterm
export TZ=America/New_York
print_header "$(basename $(readlink -f $0)) launched at $(date +%c)"
if [ ! -d "${stress_test_output_directory}" ]; then
  mkdir "${stress_test_output_directory}"
fi
rm -rf "${stress_test_output_directory}"/[0-9]*
rm -rf "${main_function_pid_list}"
rm -rf "${send_curl_commands_pid_list}"
rm -rf "${terminal_output}"
for i in $(seq 1 ${number_of_threads})
do
mkdir "${stress_test_output_directory}"/${i}_Thread
done
}

#===================================================================
print_header()
#===================================================================
{
delimiter="$(for i in $(seq 1 ${#1}); do echo -n "="; done)"
echo -e "${delimiter}\n${1}\n${delimiter}"
}

#===================================================================
cleanup()
#===================================================================
{
echo "Done!"
print_header "$(basename $(readlink -f $0)) finished at $(date +%c)"
}

#===================================================================
send_curl_commands()
#===================================================================
{
count=0
counter="$(echo ${1})"
while [ ${count} -lt ${repeat_task} ]
do
	while read one_url 
	do
	formated_one_url="$(echo ${one_url}|sed 's/.*http//g;s/s//g;s/\///g;s/://g')"
	curl_command="$(curl -s -k -X GET ${one_url})" 
	above_command_pid=$!
	echo "${curl_command}" > "${stress_test_output_directory}/${counter}_Thread/${count}.${formated_one_url}" 	
	echo "${above_command_pid}" >> "${send_curl_commands_pid_list}"
	done < "${process_url_file}"
	count=$((count+1))
done

}

#===================================================================
kill_csproxy()
#===================================================================
{
/usr/bin/expect -c '
spawn ssh "'"root@${ip_of_rkm}"'" /root/QA/kill_csproxy.sh
expect {
 -re ".*es.*o.*" {
 exp_send "yes\r"
 exp_continue
 }
 -re "sword" {
 exp_send "notser007\r"
 }
  }
  interact'
}

#===================================================================
send_kill_csproxy_to_rkm()
#===================================================================
{
expect_command=$(/usr/bin/expect -c '
spawn /usr/bin/scp  kill_csproxy.sh "'"root@${ip_of_rkm}":/root/QA'"
expect {
 -re ".*es.*o.*" {
 exp_send "yes\r"
 exp_continue
 }
 -re "sword" {
 exp_send "notser007\r"
 }
  }
  interact')
echo "${expect_command}" >> "${terminal_output}"
echo "Sent kill_csproxy.sh to RKM"

}

#===================================================================
settings_for_kill_csproxy()
#===================================================================
{
interval_minutes="$(cat $(dirname $(readlink -f $0))/settings.txt|grep -i "In what"|cut -d":" -f2)"
while true;
do
      curl_process_count=$(ps -fed | grep curl |grep -v auto|wc -l)
	  #echo "${curl_process_count}"
	  if [[ "${curl_process_count}" -gt 10 ]]; then
	  run_kill_csproxy "${interval_minutes}"
	  else
	  return 0
	  fi
done
}

#===================================================================
run_kill_csproxy()
#===================================================================
{
input="$(echo "${1}")"
	if [[ $((10#$(date -d 'now' +%M)%10#$input)) == 0 ]]; then 
	kill_csproxy
	fi
}

#===================================================================
main_function()
#===================================================================
{
temp=0
while [ ${temp} -lt ${number_of_threads} ]
do
send_counter=$(($temp+1))
send_curl_commands $send_counter &
above_function_command_pid=$!
echo "${above_function_command_pid}" >> "${main_function_pid_list}"
temp=$(($temp+1))
done
echo "Completed Threads Creation" 
echo "Launching csproxy kill/launch commands on RKM. You can see the status at ${terminal_output}"
settings_for_kill_csproxy >> "${terminal_output}" 
echo "Now we are waiting for Processes to complete which was launched by Threads" 
export -f check_processes
cat "${main_function_pid_list}" | parallel check_processes :::
}

#===================================================================
check_processes()
#===================================================================
{
pid_info_from_main_function_file="$(echo ${1})"
while [ -e /proc/${pid_info_from_main_function_file} ]; do sleep 1; done 

}
#===================================================================
# the actual script
#===================================================================
prepare_environment
send_kill_csproxy_to_rkm
main_function
cleanup
