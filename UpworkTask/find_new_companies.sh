#!/bin/bash

#===================================================================
# derived variables
#===================================================================

parent_url="http://www.vision-net.ie/Business-Barometer/Gazette-New-Companies/"
actual_domain="$(echo ${parent_url}|cut -d"/" -f3)"
http_from_domain="http://"
pad_http_to_domain="$(echo ${http_from_domain}${actual_domain})"
url_entry="$(wget -q "${parent_url}" -O -)"
raw_dump_from_url="$(dirname $(readlink -f $0))/raw_dump_from_url.txt"
echo "${url_entry}" > "${raw_dump_from_url}"
temp_file="$(dirname $(readlink -f $0))/temp_file.txt"
temp_file_1="$(dirname $(readlink -f $0))/temp_file_1.txt"

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
export TZ=America/Chicago
print_header "$(basename $(readlink -f $0)) launched at $(date +%c)"
echo -e "\nThis script takes ~1 second to complete."
rm -rf *2017.txt
}

#===================================================================
cleanup()
#===================================================================
{
print_header "$(basename $(readlink -f $0)) finished at $(date +%c)"
}


#===================================================================
find_new_companies()
#===================================================================
{
list_of_updates_by_dates="$(awk "/By Business Barometer/,/Company set ups in the above list/" ${raw_dump_from_url}| grep "<a"|tr -d " " |egrep "ofJanuary|ofFebruary|ofMarch|ofApril|ofMay|ofJune|ofJuly|ofAugust|ofSeptember|ofOctober|ofNovember|ofDecember"|sed 's/^[ \t]*//g'| cut -d">" -f5 |cut -d"<" -f1)"
count_of_updates_by_dates="$(echo "${list_of_updates_by_dates}"|wc -l)"
counter=1
while [[ $count_of_updates_by_dates -gt 1 ]]
do
awk_input_one=$(echo "${list_of_updates_by_dates}"|sed -n ${counter}p)
awk_input_two=$(echo "${list_of_updates_by_dates}"|sed -n $((${counter}+1))p)
export counter=$(($counter+1))
awk "/By Business Barometer/,/Company set ups in the above list/" "${raw_dump_from_url}"| tr -d " " | awk "/${awk_input_one}/,/${awk_input_two}/"|grep "<ac"|sed 's/^[ \t]*//g'|cut -d"=" -f5|sed 's/"//g;s/\/a//g;s/<//g;s/\/td//g;s/>/,/;s/>>//g' > "${temp_file}"
awk "/By Business Barometer/,/Company set ups in the above list/" "${raw_dump_from_url}" | tr -d " " | awk "/${awk_input_one}/,/${awk_input_two}/"|egrep "<ac|<td>"|sed 's/^[ \t]*//g' |cut -d"=" -f5|sed 's/"//g;s/\/a//g;s/<//g;s/\/td//g;s/>/,/;s/>>//g;s/td,//g;s/>//g'|sed '/^[[:space:]]*$/d' > "${temp_file_1}"
format_text $awk_input_one
export count_of_updates_by_dates=$(($count_of_updates_by_dates-1))
if [[ $count_of_updates_by_dates -eq 1 ]]; then
awk "/By Business Barometer/,/Company set ups in the above list/" "${raw_dump_from_url}"| tr -d " " | awk "/${awk_input_two}/,/Companysetupsintheabovelist/"|grep "<ac"|sed 's/^[ \t]*//g'|cut -d"=" -f5|sed 's/"//g;s/\/a//g;s/<//g;s/\/td//g;s/>/,/;s/>>//g' > "${temp_file}"
awk "/By Business Barometer/,/Company set ups in the above list/" "${raw_dump_from_url}" | tr -d " " | awk "/${awk_input_two}/,/Companysetupsintheabovelist/"|egrep "<ac|<td>"|sed 's/^[ \t]*//g' |cut -d"=" -f5|sed 's/"//g;s/\/a//g;s/<//g;s/\/td//g;s/>/,/;s/>>//g;s/td,//g;s/>//g'|sed '/^[[:space:]]*$/d' > "${temp_file_1}"
format_text $awk_input_two
fi
done
}

#===================================================================
format_text()
#===================================================================
{
input="$(echo ${1}|sed 's/,//g'|sed 's/of/-/g;s/201/-201/g')"
echo -e "date company_number company_name company_partial_address company_link" | column -t > "$(dirname $(readlink -f $0))/${input}.txt"
while read formated_input
do
company_number=$(echo ${formated_input}|cut -d, -f1|rev|cut -d"-" -f1|rev)
company_name=$(echo ${formated_input}|cut -d, -f2)
company_link=$(echo ${formated_input}|cut -d, -f1|rev|cut -d"-" -f2-|rev)
formated_company_link=$(echo "${pad_http_to_domain}"${company_link})
company_partial_address=$(cat ${temp_file_1}|grep -A 1 $(echo ${company_number})|tail -1)
echo -e "${input} ${company_number} ${company_name} ${company_partial_address} ${formated_company_link}" | tr -d "\015" |column -t >> "$(dirname $(readlink -f $0))/${input}.txt"
done < "${temp_file}"
rm -rf "${temp_file}"
rm -rf "${temp_file_1}"

}
#===================================================================
# the actual script
#===================================================================
prepare_environment
find_new_companies
cleanup

#===================================================================
# th-th-th-that's all folks!
#===================================================================
exit 0
