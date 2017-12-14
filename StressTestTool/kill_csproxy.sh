#===================================================================
kill_csproxy()
#===================================================================
{
      	pid_of_csproxy="$(sudo pidof csproxy)" 
		echo "pidof of csproxy before killing:${pid_of_csproxy}" 
		echo "Sending svc -d /etc/service/csproxy" 
		sudo /usr/bin/svc -d /etc/service/csproxy
				
		while [ -n "$(sudo pidof csproxy)" ]
		do
		echo "Time is $(date +%T).Still csproxy is not killed" 
		sleep 5
		done
        
		if [[ "$(sudo pidof csproxy)" != "${pid_of_csproxy}" ]]; then
		 echo "csproxy is killed" 
		fi
		 
        echo "Sending svc -u /etc/service/csproxy" 
		sudo /usr/bin/svc -u /etc/service/csproxy
		
		while [ -z "$(sudo pidof csproxy)" ]
		do
		echo "Time is $(date +%T).Sent svc -u /etc/service/csproxy waiting for csproxy to restart" 
		sleep 5
		done
		
		if [[ -n "$(sudo pidof csproxy)" ]]; then
		      pid_of_csproxy_after_killing="$(sudo pidof csproxy)"
              echo "pid of csproxy after killing:${pid_of_csproxy_after_killing}" 			  
		fi
		sleep 5
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
print_header "$(basename $(readlink -f $0)) finished at $(date +%c)"
}

#===================================================================
prepare_environment()
#===================================================================
{
export TERM=xterm
export TZ=America/New_York
print_header "$(basename $(readlink -f $0)) launched at $(date +%c)"
}

#===================================================================
# the actual script
#===================================================================
prepare_environment
kill_csproxy
cleanup