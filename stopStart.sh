usage_message="$(echo -e "USAGE: stopStart.sh -m\n  -m <Meter ShortCut (\"PR\", \"PO\", \"OS\", \"SM\")>\n")"
[[ -z "$(echo "$@"|grep "\-m")" ]] && echo -e "${usage_message}" && exit 1

while getopts ":m:" opt
do
  case "${opt}" in
	m) export meter_shortcut="${OPTARG}" ;;
	\?) echo "Invalid option: -$OPTARG" >&2 ; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2 ; exit 2 ;;
  esac
done

#===================================================================
# static variables
#===================================================================
case "${meter_shortcut}" in
	"PR") export meter_shortcut="PermissionResearch" ;;
	"PO") export meter_shortcut="PremierOpinion" ;;
	"OS") export meter_shortcut="OpinionSquare" ;;
	"SM") export meter_shortcut="SwissMedia" ;;
esac

#===================================================================
prepare_environment()
#===================================================================
{
export TERM=xterm
print_header "stopStart.sh launched at $(date +%c)"
beforeRestartpidOfMeter=$(ps -Af | grep ${meter_shortcut}D|grep -v "grep ${meter_shortcut}D"|awk -F" " '{print $2}')
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
print_header "stopStart.sh finished at $(date +%c)"
}

#===================================================================
stopmeter()
#===================================================================
{
sudo launchctl unload /Library/LaunchDaemons/${meter_shortcut}.plist
sleep 10
}

#===================================================================
startmeter()
#===================================================================
{
sudo launchctl load /Library/LaunchDaemons/${meter_shortcut}.plist
sleep 10
}

#===================================================================
getPidOfMeter()
#===================================================================
{
AfterRestartpidOfMeter=$(ps -Af | grep ${meter_shortcut}D|grep -v "grep ${meter_shortcut}D"|awk -F" " '{print $2}')
if [[ "${beforeRestartpidOfMeter}" != "${AfterRestartpidOfMeter}" ]]; then
echo -e "SuccessFully Stopped and Restarted with New ProcessID:${AfterRestartpidOfMeter}"
fi
}

#===================================================================
savelogs()
#===================================================================
{
now=$(date +'%Y%m%d%H%M')
user="$USER"
directory="/Users/$user/Desktop/ContentID"
if [ ! -d "${directory}" ]; then
   mkdir "${directory}"
fi
if [ -f "/tmp/ContentId.txt" ]; then
sudo mv /tmp/ContentId.txt "${directory}"/"${now}"_ContentId.txt
fi
if [ -f "/tmp/MacMeter.log" ]; then
sudo cp /tmp/MacMeter.log "${directory}"/"${now}"_MacMeter.log
fi
}

#===================================================================
main()
#===================================================================
{
read -p 'Do you want to save logs?(y/n) ' noconf
if [ $noconf == y ]; then
	echo -e "\nSavinglogs...\n"
	savelogs
fi
read -p 'You may want to restart meter twice. Restart meter?(y/n) ' answer
if [ $answer == "y" ]; then
	echo -e "\nRestarting meter now...\n"
	stopmeter
	startmeter
	echo -e "Restarting meter 2nd time...\n"
	stopmeter
	startmeter
	getPidOfMeter
else
read -p 'You may want to restart meter Once. Restart meter?(y/n) ' answer1	
	if [ $answer1 == "y" ]; then
		echo -e "\nRestarting meter now...\n"
		stopmeter
		startmeter
		getPidOfMeter
	else
		read -p 'You may want to Only stop meter Once. Restart meter?(y/n) ' answer1
			if [ $answer1 == "y" ]; then
				echo -e "\nStopping meter now...\n"
				stopmeter
			else
		read -p 'You may want to Only Start meter Once. Restart meter?(y/n) ' answer1
				if [ $answer1 == "y" ]; then
					echo -e "\nStarting meter now...\n"
					startmeter
					getPidOfMeter
				fi
		   fi	
	fi
fi
}


#===================================================================
# the actual script
#===================================================================
prepare_environment
main
cleanup
