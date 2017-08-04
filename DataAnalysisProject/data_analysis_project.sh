

#===================================================================
# static variables
#===================================================================
input_file="$(dirname $(readlink -f $0))/by_city_panelists.csv"
updated_file="$(dirname $(readlink -f $0))/updated_by_city_panelists.csv"

#===================================================================
prepare_environment()
#===================================================================
{
export TERM=xterm
export TZ=America/New_York
print_header "$(basename $(readlink -f $0)) launched at $(date +%c)"
rm -rf *with*.csv
rm -rf v_p_ids*.csv
rm -rf *.txt
echo -e "Script would take approximately 8 minutes to complete!"
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
rm -rf *with*.csv
rm -rf v_p_ids*.csv
rm -rf "$(dirname $(readlink -f $0))/repeat_records.txt"
echo -e "Results are in Present Working Directory!"
print_header "$(basename $(readlink -f $0)) finished at $(date +%c)"
}
#===================================================================
main_function()
#===================================================================
{

cat "${input_file}" | sed 's/"//g' | sed 's/\(.*\),/\1--/' > "${updated_file}"
#for city in "CHICAGO--IL"  #$(cut -d, -f3 "${updated_file}" | grep -v city_state |sort -u | awk '!/^$/')
for city in $(cut -d, -f3 "${updated_file}" | grep -v city_state |sort -u | awk '!/^$/')
do
	parsed_city="$(echo ${city}|cut -d"-" -f1)"
	city_parsing "${parsed_city}" > "$(dirname $(readlink -f $0))/${parsed_city}_output.txt"

done

}

#===================================================================
city_parsing()
#===================================================================
{
	updated_city="$(echo ${1})"
	cat "${updated_file}" | grep -v "vendor_id" | sort -u -t, -k1,1 -k2,2 -k3,3 | grep -i "${updated_city}" > "$(dirname $(readlink -f $0))/${updated_city}_with_duplicated.csv"
	cat "${updated_file}" | grep -v "vendor_id" | sort -u -t, -k1,1 -k2,2 | grep -i "${updated_city}" > "$(dirname $(readlink -f $0))/${updated_city}_without_duplicated.csv"
	comm -3 <(cut -d, -f1,2 "${updated_city}"_with_duplicated.csv | sort) <(cut -d, -f1,2 "${updated_city}"_without_duplicated.csv| sort) > "$(dirname $(readlink -f $0))/v_p_ids_other_than_${updated_city}.csv"
	gross_count="$(cat ${updated_city}_with_duplicated.csv| wc -l)"
	conservative_count="$(cat ${updated_city}_without_duplicated.csv|wc -l)"
	other_than_intended_city="$(cat v_p_ids_other_than_${updated_city}.csv|wc -l)"
	echo -e "Sum of Gross Count of ${updated_city}:${gross_count}"
	echo -e "Sum of Conservative count of ${updated_city}:${conservative_count}"
	echo -e "Count of ID's other than ${updated_city} is:${other_than_intended_city}"
	echo -e "\n"

	while read id_set
	do
		cat "${updated_file}" | grep -i "${id_set}" |grep -v "${updated_city}" > "$(dirname $(readlink -f $0))/repeat_records.txt"
		count_of_repeated_records="$(cat $(dirname $(readlink -f $0))/repeat_records.txt| wc -l)"
		echo -e "Count of Repeated Records other than ${updated_city} is:${count_of_repeated_records}"
		echo -e "---------------------------------------------------------"
		cat "$(dirname $(readlink -f $0))/repeat_records.txt" 
		echo -e "---------------------------------------------------------"
	done < "$(dirname $(readlink -f $0))/v_p_ids_other_than_${updated_city}.csv"
}

#===================================================================
# the actual script
#===================================================================
prepare_environment
main_function
cleanup
