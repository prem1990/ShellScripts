#!/bin/bash

#===================================================================
# static variables
#===================================================================
parentPath=$(pwd)
settings="${parentPath}/settings.txt"
configuration="${parentPath}/DoNotTouch/config.txt"
testDirectory="${parentPath}/TestDir"
OSAFiles="${parentPath}/OSAFiles"
ExtractedFiles="${parentPath}/ExtractedFiles"
Installers="${parentPath}/Installers"
Rules="${parentPath}/Rules"
AllFiles="${parentPath}/DoNotTouch/AllFiles.txt"
OSAList="${parentPath}/DoNotTouch/OSAList.txt"
Results="${parentPath}/OSAAutomationResults.txt"
securityTestResults="${parentPath}/securityTestResults.txt"
BrandFileList="${parentPath}/DoNotTouch/BrandFileList.txt"
codesignFile="/usr/bin/codesign"
testupgradexml="${parentPath}/DoNotTouch/testupgrade.xml"
FfxFiles="${parentPath}/DoNotTouch/FirefoxFiles.txt"
osarchivetool="${parentPath}/DoNotTouch"/osarchive
rulefile="rule14m_prem.pli"
modifiedrulefile="rule14mAutomationReston.pli"
approvedOsaList="${parentPath}/DoNotTouch/ApprovedOSAList.txt"
email_addresses=$(grep "EmailAddress" "${configuration}"|cut -d"=" -f2)
security_test_email_subject=$(echo "${securityTestResults}"|rev|cut -d"/" -f1|rev|cut -d"." -f1)
email_subject=$(echo "${Results}"|rev|cut -d"/" -f1|rev|cut -d"." -f1)
newBrand_email_subject="Hello .... NEW BRAND FOUND!!!!"



#===================================================================
prepare_environment()
#===================================================================
{
export TERM=xterm
print_header "OsaAutomation.sh launched at $(date +%c)"
if [ -d "${testDirectory}" ]; then
   umount -f "${testDirectory}/"  2>/dev/null
fi
rm -rf "${OSAFiles}"
rm -rf "${ExtractedFiles}"
rm -rf "${Installers}"
rm -rf "${Rules}"
#rm -rf "${parentPath}"/osarchive
rm -rf "${parentPath}/Results.txt"
rm -rf "${parentPath}"/*.signature.txt
rm -rf "${parentPath}"/updated*
rm -rf "${parentPath}"/upgrade.xml
rm -rf "${securityTestResults}"
if [[ -z $(find /usr -type f -name "*codesign" 2>/dev/null) ]]; then
echo "The is no file called codesign under /usr/bin/, So Please install codesign using Xcode and then run the script"
exit 1
fi
echo -e "\nThis script takes ~10 minutes to complete."
# Checking /etc/hosts files settings, adding them if they're not there
echo -e "\nChecking if host file settings are present...\n"
if [[ $(grep "securestudies.com" /etc/hosts) ]]; then
	echo -e "Host file settings present in /etc/hosts, leaving file intact\n"
else
	echo -e "Backing up /etc/hosts file and then adding required string to /etc/hosts file...\n"
	sudo cp /etc/hosts /etc/hosts.bak
	echo -e "please copy the following information in /etc/hosts and relaunch the script"
	echo "66.119.41.217   rules.securestudies.com" 
	echo "66.119.41.148   oss-content.securestudies.com"
	exit
fi
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
checkcleanup=$(ls -lrt "${testDirectory}")
if [ $(echo "${#checkcleanup}") -ne 0 ]; then
   umount -f "${testDirectory}/"  
else
rm -rf "${testDirectory}"
fi
rm -rf "${parentPath}"/*.signature.txt
#rm -rf "${parentPath}"/osarchive
rm -rf "${OSAFiles}"
rm -rf "${ExtractedFiles}"
rm -rf "${Installers}"
rm -rf "${Rules}"
rm -rf "${parentPath}"/updated*
rm -rf "${parentPath}"/upgrade.xml
rm -rf "${parentPath}"/temp.txt
rm -rf "${securityTestResults}"
rm -rf "${Results}"
print_header "OsaAutomation.sh finished at $(date +%c)"
}


#===================================================================
email_results()
#===================================================================
{
fileToBeSent=$(echo ${1})
address=$(echo ${2})
subject=$(echo ${3})

if [[ -s "${fileToBeSent}" ]] ; then
   	echo -e "To: ${address}\nSubject: ${subject}\nMIME-Version: 1.0\nContent-Type: text\nContent-Disposition: attachment\n$(cat "${fileToBeSent}")\n"|/usr/sbin/sendmail -F "OSAAutomation Script" -f "pbankala@comscore.com" -t "${address}" && echo -e "\n${subject} have been emailed.\n"
else
    echo -e "\nThere are no results to report.\n"
fi

}


#===================================================================
Main()
#===================================================================
{
buildVersion=$(grep "buildVersion" "${settings}"|cut -d"=" -f2)
if [[ "${#buildVersion}" -eq 0 ]]; then
echo "Please enter Build Version in ${settings}. Thank you!"
exit
fi
machinepassword=$(grep "machinePassword" "${settings}"|cut -d"=" -f2)
if [[ "${#machinepassword}" -eq 0 ]]; then
echo "Please enter Machine Passowrd in ${settings}. Thank you!"
exit
fi
#bidPart=$(date|md5|head -c11)
#bid="1jhduevHGFD${bidPart}"
#bid=$(grep "bid" "${settings}"|cut -d"=" -f2)
#if [[ "${#bid}" -eq 0 ]]; then
#echo "Please enter bid in ${settings}. Thank you!"
#exit
#fi
buildServerLocation=$(grep "buildServerLocation" "${configuration}"|cut -d"=" -f2)
ossServerLocation=$(grep "ossServerLocation" "${configuration}"|cut -d"=" -f2)
if [[ -n $(echo "${ossServerLocation}"|grep "cviadmsd01") ]]; then
ossServerLocation=$(grep "ossServerLocation" "${configuration}"|cut -d"=" -f2|sed "s/\/rules-segqa/.office.comscore.com\/rules-segqa/g")
fi
ossArchiveToolLocation=$(grep "ossArchiveToolLocation" "${configuration}"|cut -d"=" -f2)
userID=$(grep "userID" "${configuration}"|cut -d"=" -f2)
password=$(grep "networkPassword" "${configuration}"|cut -d"=" -f2)

correctTotalFiles=$(grep "correctTotalFiles" "${configuration}"|cut -d"=" -f2)
numberOfOSAFiles=$(grep "numberOfOSAFiles" "${configuration}"|cut -d"=" -f2)
chromeFileCount=$(grep "chromeFileCount" "${configuration}"|cut -d"=" -f2)
FFXFileCount=$(grep "FFXFileCount" "${configuration}"|cut -d"=" -f2)
NumberofPassExpected=$(grep "TotalNumberofPassExpected" "${configuration}"|cut -d"=" -f2)
NumberofFailExpected=$(grep "TotalNumberofFailExpected" "${configuration}"|cut -d"=" -f2)


buildServerLocationWithIDPassword=$(echo "${buildServerLocation}"|sed "s,//,//${userID}:${password}@,g")
#ossServerLocationWithIDPassword=$(echo "${ossServerLocation}"|sed "s,//,"'"//comscore_office;"'"${userID}:${password}@,g")
ossServerLocationWithIDPassword=$(echo "${ossServerLocation}"|sed "s,//,//comscore_office;${userID}:${password}@,g")
ossArchiveToolLocationWithPassword=$(echo "${ossArchiveToolLocation}"|sed "s,//,//${userID}:${password}@,g")

#CreateDirectories
directoryCreation "${testDirectory}"
directoryCreation "${OSAFiles}"
directoryCreation "${ExtractedFiles}"
directoryCreation "${Installers}"
directoryCreation "${Rules}"

#mountbuildServerLocationAndCopy
mountTheDirectory "${buildServerLocationWithIDPassword}" "${testDirectory}"
CopyTheContents "${testDirectory}" "${OSAFiles}" "${buildVersion}"
umount -f "${testDirectory}/"


#mountossArchiveToolLocationAndCopy
#mountTheDirectory "${ossArchiveToolLocationWithPassword}" "${testDirectory}"
#cp "${testDirectory}"/osarchive "${parentPath}"
#umount -f "${testDirectory}/"

CheckForNewBrand

ExtractFilesFromOSA

#BuildFileList

DoCompare

#mountInstallersDirectoryAndCopy
mountTheDirectory "${buildServerLocationWithIDPassword}/build_${buildVersion}/installers" "${testDirectory}"
CopyTheContents "${testDirectory}" "${Installers}" "${buildVersion}"
umount -f "${testDirectory}/"

#mountrulesDirectoryAndCopy
modifiedossServerLocationWithIDPassword=$(echo "${ossServerLocationWithIDPassword}"|rev|cut -d"/" -f2-|rev)
mountTheDirectory "${modifiedossServerLocationWithIDPassword}/rules" "${testDirectory}"
CopyTheContents "${testDirectory}" "${Rules}"
umount -f "${testDirectory}/"

ModifyRule14m

#mountrulesDirectoryAndCopyModifiedRule
mountTheDirectory "${modifiedossServerLocationWithIDPassword}/rules" "${testDirectory}"
CopyTheContents "${Rules}" "${testDirectory}"
umount -f "${testDirectory}/"

uninstallQaToolsPackage

install-verifyContents-uninstall-Brands

#PurposeuploadToTestServer
mountTheDirectory "${modifiedossServerLocationWithIDPassword}/meter" "${testDirectory}"
CopyTheContents "${OSAFiles}" "${testDirectory}"
umount -f "${testDirectory}/"

}

#===================================================================
directoryCreation()
#===================================================================
{
ifTest=$(echo ${1})
if [ ! -d "${ifTest}" ]; then
   mkdir "${ifTest}"
fi
}

#===================================================================
mountTheDirectory()
#===================================================================
{
mountSource=$(echo "${1}")
mountDestination=$(echo "${2}")
if [[ -n $(echo "${mountSource}"|grep -i "cviadmsd01") ]]; then
mount_smbfs "${mountSource}" "${mountDestination}/" 
commandStatus=$(echo $?)
	if [[ ${commandStatus} -ne 0 ]]; then 
		echo "ERROR: Please Connect to Server by giving following address in : GO - Connect to Server and Enter your network Credentials" 
		echo "smb://cviadmsd01.office.comscore.com/rules-segqa/rules"  
		echo  "Killing Script"
		exit 1 
		fi
else
	mount -t smbfs "${mountSource}" "${mountDestination}/"
fi
}

#===================================================================
CopyTheContents()
#===================================================================
{
copySource=$(echo "${1}")
copyDestination=$(echo "${2}")
copyOsaBuildVersion=$(echo "${3}")
if [[ -n $(echo "${copySource}"|grep -i "OSAFiles") ]]; then
cp "${copySource}"/*.osa "${copyDestination}"
temp=$(echo "${ossServerLocation}"|rev|cut -d"/" -f2-|rev)
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: OSA files uploaded to ${temp}/meter"
elif [[ -n $(echo "${copyDestination}"|grep -i "Installers") ]]; then
cp "${copySource}"/*_"${copyOsaBuildVersion}" "${copyDestination}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): LOG: Download Installer files is Done!"
elif [[ -n $(echo "${copyDestination}"|grep -i "rules") ]]; then
cp "${copySource}/${rulefile}" "${Rules}"
#cp "${copySource}/${actualruleFile}" "${Rules}/${rulefile}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): LOG: Download ${rulefile} file Done!"
#echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): LOG: Copied ${actualruleFile} into ${rulefile} file Done!"
elif [[ -n $(echo "${copySource}"|grep -i "Rules") ]]; then
cp  "${copySource}/${modifiedrulefile}" "${copyDestination}"
echo -e "\n$(date +"%m/%d/%Y %H:%M:%S %r"): LOG: Upload ${modifiedrulefile} file Done!"
else
cp "${copySource}/build_${copyOsaBuildVersion}"/*.osa "${copyDestination}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): LOG: Download OSA files Done!"
fi
}

#===================================================================
CheckForNewBrand()
#===================================================================
{
tempVar=0
for singleBrand in $(ls -l "${OSAFiles//[[:cntrl:]]/}"|column -t|rev|column -t|cut -d" " -f1|rev|tail -n +2|cut -d"." -f1|rev|cut -d"_" -f2-|rev)
do
if [[ -z $(cat "${approvedOsaList}" | grep "${singleBrand/[[:cntrl:]]/}") ]]; then
	NeedConfigChange "${singleBrand/[[:cntrl:]]/}"
	retval=$?
	if [[ "${retval}" == 1 ]]; then
	tempVar=$(($tempVar+1))
	sleep 10
	fi
fi
done
if [[ "${tempVar}" -gt 0 ]]; then
email_results "${Results}" "${email_addresses}" "${newBrand_email_subject}"
cleanup
exit
fi
}

#===================================================================
NeedConfigChange()
#===================================================================
{
NewBrand=$(echo "${1}")
echo -e "\n$(date +"%m/%d/%Y %H:%M:%S %r"): NOTE: NewBrand Found:${NewBrand//[[:cntrl:]]/}\n"
echo -e "**********************************************************************************"
echo -e "Please Complete the Following steps and Relaunch the script"
echo -e "**********************************************************************************"
echo -e "\nStep 1: Please add the ${NewBrand//[[:cntrl:]]/} name into the ${approvedOsaList//[[:cntrl:]]/} File!"
echo -e "Step 2: There should be NewBrand information in rule14m_prem.pli at //cviadmsd01/rules-segqa/"
echo -e "Step 3: There should be NewBrand Name in  ${OSAList//[[:cntrl:]]/} file!"
echo -e "Step 4: Please increment the numberOfOSAFiles variable in ${configuration//[[:cntrl:]]/} file!"
echo -e "Step 5: Please Update TotalNumberofPassExpected Variable in ${configuration//[[:cntrl:]]/} by adding 306 to existing variable Value!"
return 1
}

#===================================================================
ExtractFilesFromOSA()
#===================================================================
{
NumberOfOSA=0
for SingleOSAList in $(cat "${OSAList}")
do
#countTheNumberOfOsaFiles
	if [[ -n $(find "${OSAFiles}" -type f -name "${SingleOSAList//[[:cntrl:]]/}_${buildVersion//[[:cntrl:]]/}.osa") ]]; then
	NumberOfOsa=$(($NumberOfOsa+1))
	fi
	"${osarchivetool}" -e "${OSAFiles}/${SingleOSAList//[[:cntrl:]]/}_${buildVersion//[[:cntrl:]]/}.osa" 1>/dev/null
	unzip "${SingleOSAList//[[:cntrl:]]/}.zip" -d "${ExtractedFiles}/${SingleOSAList//[[:cntrl:]]/}" 1>/dev/null
	rm "${SingleOSAList//[[:cntrl:]]/}.zip"
done
if [[ "${numberOfOSAFiles}" -eq "${NumberOfOsa}" ]]; then
	echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: ${NumberOfOsa} OSA files Found and is correct"
else
	echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: ${NumberOfOsa} OSA files Found and is wrong"
fi
}


#===================================================================
BuildFileList()
#===================================================================
{
for OSAList in $(cat "${OSAList}"|grep -i "KantarResearch")
do
find "${ExtractedFiles}/${OSAList//[[:cntrl:]]/}" -type f |sed 's/.*ExtractedFiles//'|rev| sed 's/.$//'|rev|cut -d"/" -f2- > "${AllFiles}"
done
}

#===================================================================
DoCompare()
#===================================================================
{
for SingleOSAListItem in $(cat "${OSAList}")
do
echo -e "*******************************${SingleOSAListItem//[[:cntrl:]]/}****************************************************"
	if [[ -n $(find "${OSAFiles}" -type f -name "${SingleOSAListItem//[[:cntrl:]]/}_${buildVersion//[[:cntrl:]]/}.osa") ]]; then
		echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: ${SingleOSAListItem//[[:cntrl:]]/}_${buildVersion//[[:cntrl:]]/}.osa exists"
	else
	echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: ${SingleOSAListItem//[[:cntrl:]]/}_${buildVersion//[[:cntrl:]]/}.osa does not exist"
	exit 1
	fi
count=0
	while read singleBrandFile
	do
		if [[ -n $(echo "${singleBrandFile}"|grep ".bms") ]]; then
		    actual_file=$(echo "${singleBrandFile}"|awk -F"/" '{print $NF}')
		    actual_directory=$(echo "${singleBrandFile}"|sed "s/${actual_file}//g")
		    actual_file_sub="zip"
		    if [[ "${actual_file/$actual_file_sub}" != "${actual_file}" ]]; then
		    actual_file=$(echo "${actual_file}"|cut -d. -f2)
		    fi
		    if [[ -n $(find "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}" -type f -name "*${actual_file}*"|grep "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_directory//[[:cntrl:]]/}") ]]; then
			echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: $(find "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}" -type f -name "*${actual_file}*"|grep "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_directory//[[:cntrl:]]/}") exists"
			count=$(($count+1))
			else
			#echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: $(find "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}" -type f -name "*${actual_file}*"|grep "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_directory//[[:cntrl:]]/}") does not exist"
			echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: ${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_directory//[[:cntrl:]]/}${actual_file//[[:cntrl:]]/} does not exist"
			fi
		elif [[ -n $(echo "${singleBrandFile}"|grep "KantarResearchMeter") ]]; then
		     actual_file=$(echo "${singleBrandFile}"|awk -F"/" '{print $NF}')
		     modified_file=$(echo "${singleBrandFile}"|sed "s/KantarResearchMeter/${SingleOSAListItem//[[:cntrl:]]/}/g"|awk -F"/" '{print $NF}')
		     actual_directory=$(echo "${singleBrandFile}"|sed "s/KantarResearchMeter/${SingleOSAListItem//[[:cntrl:]]/}/g")
		     if [[ -n $(find "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}" -type f -name "*${modified_file}*"|grep "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_directory//[[:cntrl:]]/}") ]]; then
			 echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: ${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_directory//[[:cntrl:]]/} exists"
			 count=$(($count+1))
			 else
			 echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: ${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_directory//[[:cntrl:]]/} does not exist"
			 fi	
		else
		     actual_file=$(echo "${singleBrandFile}")
		     if [[ -n $(find "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}" -type f -name "*${actual_file}*") ]]; then
			 echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: ${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_file} exists"
			 echo -e "------${SingleOSAListItem//[[:cntrl:]]/}: Check for Brand Information--------"
			 cp "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}"/${actual_file}  "${parentPath}" 
			 cat "${testupgradexml}" | sed "s/PermissionResearch/${SingleOSAListItem//[[:cntrl:]]/}/g" > "${parentPath}"/updated.upgrade.xml
			 if [[ -z $(diff "${parentPath}/${actual_file}"  "${parentPath}"/updated.upgrade.xml) ]]; then
			 echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: ${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_file} Contains Brand Information"
			 cat "${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_file}"
			 else 
			 echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: ${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_file} Does not contain Brand Information"
			 fi
			 count=$(($count+1))
			 else 
			 echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: ${ExtractedFiles}/${SingleOSAListItem//[[:cntrl:]]/}/${actual_file} does not exist"
			 fi	
		fi
	done < "${AllFiles}"
	echo -e "------${SingleOSAListItem//[[:cntrl:]]/} Files Check--------"
	if [[ "${count}" -eq "${correctTotalFiles}" ]]; then
	echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Total number of files in ${SingleOSAListItem//[[:cntrl:]]/} = ${count} and is correct"
	else 
	echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Total number of files in ${SingleOSAListItem//[[:cntrl:]]/} = ${count} and is not correct"
	fi
	FFXAndChromeFileCheck "${SingleOSAListItem}"
	SignatureCheckAndVersionCheck "${SingleOSAListItem}"
done
}

#===================================================================
FFXAndChromeFileCheck()
#===================================================================
{
eachOsaList=$(echo "${1}")
for singleFFXChromeZip in $(find "${ExtractedFiles}/${eachOsaList//[[:cntrl:]]/}" -type f -name "*.zip")
do
ffxcount=0
		if [[ $(echo "${singleFFXChromeZip//[[:cntrl:]]/}"|grep -i "chrome") ]]; then
			singleChromeDirectory=$(echo "${singleFFXChromeZip//[[:cntrl:]]/}"|rev| cut -d"/" -f2-|rev)
			unzip "${singleFFXChromeZip//[[:cntrl:]]/}" -d "${singleChromeDirectory//[[:cntrl:]]/}" 1>/dev/null
			if [[ $(find "${singleChromeDirectory//[[:cntrl:]]/}" -type f |egrep -v ".zip|chkUpgrade"|wc -l|sed 's/^[ \t]*//') -eq "${chromeFileCount}" ]]; then
					echo -e "------${eachOsaList//[[:cntrl:]]/} CHROME File Count Check--------"	
					echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Total number of Chrome files is $(find "${singleChromeDirectory//[[:cntrl:]]/}" -type f |egrep -v ".zip|chkUpgrade"|wc -l|sed 's/^[ \t]*//') and is correct"		
			else
					echo -e "------${eachOsaList//[[:cntrl:]]/} CHROME File Count Check--------"	
					echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Total number of Chrome files is $(find "${singleChromeDirectory//[[:cntrl:]]/}" -type f |egrep -v ".zip|chkUpgrade"|wc -l|sed 's/^[ \t]*//') and is incorrect"
			fi
					
		elif [[ -n $(echo "${singleFFXChromeZip//[[:cntrl:]]/}"|grep -i "ffox") ]]; then
			singleFFXDirectory=$(echo "${singleFFXChromeZip//[[:cntrl:]]/}"|rev| cut -d"/" -f2-|rev)
			unzip "${singleFFXChromeZip//[[:cntrl:]]/}" -d "${singleFFXDirectory//[[:cntrl:]]/}" 1>/dev/null
			for singleFFXFileInfo in $(cat "${FfxFiles}")
			do
				singleFFXFileDirectory=$(echo "${singleFFXFileInfo//[[:cntrl:]]/}"|rev| cut -d"/" -f2-|rev|sed "s/kantarresearchmeter/${eachOsaList//[[:cntrl:]]/}/g")
				singleFFXFile=$(echo "${singleFFXFileInfo}"|awk -F"/" '{print $NF}')
				if [[ -n $(find "${singleFFXDirectory//[[:cntrl:]]/}/Mozilla" -type f -name "${singleFFXFile//[[:cntrl:]]/}"|grep -i "${singleFFXFileDirectory//[[:cntrl:]]/}") ]]; then
					ffxcount=$(($ffxcount+1))
				fi
			done
				if [[ "${ffxcount}" -eq "${FFXFileCount}" ]]; then	
					echo -e "------${eachOsaList//[[:cntrl:]]/} FFX File Count Check--------"	
					echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Total number of FFX files is ${ffxcount} and is correct"
				else
					echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Total number of FFX files is ${ffxcount} and is incorrect"	
				fi
		fi
done
}

#===================================================================
SignatureCheckAndVersionCheck()
#===================================================================
{
eachOsaList=$(echo "${1}")
echo -e "------${eachOsaList//[[:cntrl:]]/} Signature & Version Check--------"
"${codesignFile}" -dv "${ExtractedFiles}/${eachOsaList//[[:cntrl:]]/}/${eachOsaList//[[:cntrl:]]/}.app" &> "${eachOsaList//[[:cntrl:]]/}".signature.txt
application=$(cat "${eachOsaList//[[:cntrl:]]/}".signature.txt|grep "^\Executable="|cut -d= -f2)
SignatureSize=$(cat "${eachOsaList//[[:cntrl:]]/}".signature.txt|grep "^\Signature size="|cut -d= -f2)
SignatureDate=$(cat "${eachOsaList//[[:cntrl:]]/}".signature.txt|grep "^\Timestamp="|cut -d= -f2)
Publisher=$(cat "${eachOsaList//[[:cntrl:]]/}".signature.txt|grep "^\Identifier="|cut -d= -f2|cut -d. -f1,2)
Product=$(cat "${eachOsaList//[[:cntrl:]]/}".signature.txt|grep "^\Identifier="|cut -d= -f2|cut -d. -f3)
versionFromInfoPlist=$(grep -A 1 "CFBundleVersion" "${ExtractedFiles}/${eachOsaList//[[:cntrl:]]/}/${eachOsaList//[[:cntrl:]]/}.app/Contents/Info.plist" | grep "<string>" | sed "s/<//g;s/string//g;s/>//g;s/\///g"|tr -d "\t")
FileVersion=$(echo "${buildVersion}")
if [[ $(echo "${application//[[:cntrl:]]/}"|awk -F"/" '{print $NF}') = "${eachOsaList//[[:cntrl:]]/}" && "${SignatureSize}" -gt 0  &&  -n "${SignatureDate}"  &&   -n "${Publisher}"  &&  -n "${Product}"  &&   "${versionFromInfoPlist}" = "${FileVersion}" ]]; then
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Application: ${application//[[:cntrl:]]/}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Verified : Signed(Size is ${SignatureSize})"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Signing Date: ${SignatureDate}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Publisher: ${Publisher}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Product: ${Product}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): PASS: Version: ${versionFromInfoPlist}\n"
else
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Application: ${application//[[:cntrl:]]/}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Verified : Signed(Size is ${SignatureSize})"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Signing Date: ${SignatureDate}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Publisher: ${Publisher}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Product: ${Product}"
echo -e "$(date +"%m/%d/%Y %H:%M:%S %r"): FAIL: Version: ${versionFromInfoPlist}\n"
fi
}

#===================================================================
ModifyRule14m()
#===================================================================
{
echo -e "\n------Modifying rule14m_prem.pli and Saving it as rule14mAutomationReston.pli--------"
echo -e "============================"
echo -e "Before rule14m_prem.pli  Modified"
echo -e "============================"
echo "-->Intall Version Section";cat "${Rules}/${rulefile}" |awk '/<package./,/<\/package>/'|sed 's/<\/package>/<\/package>\'$'\n/g'|sed 's/^$/-->Begin Upgrade Section/g'|sed '$d'
VersionFromrule14m=$(cat "${Rules}/${rulefile}"|grep -i "version="| head -1|sed 's/>//g'|awk '{print $NF}'|sed 's/"//g;s/version=//g')
if [[ "${VersionFromrule14m}" == "${buildVersion}" ]]; then
echo -e "========================================================================"
echo -e "BUILD VERSION IS SAME: Saving rule14m.pli To rule14mAutomationReston.pli"
echo -e "========================================================================"
cat "${Rules}/${rulefile}" > "${Rules}/${modifiedrulefile}"
echo "-->Intall Version Section";cat "${Rules}/${modifiedrulefile}" |awk '/<package./,/<\/package>/'|sed 's/<\/package>/<\/package>\'$'\n/g'|sed 's/^$/-->Begin Upgrade Section/g'|sed '$d'
else
echo -e "=================================================================================================="
echo -e "BUILD VERSION IS DIFFERENT: After rule14m.pli is Modified and saved to rule14mAutomationReston.pli"
echo -e "=================================================================================================="
cat "${Rules}/${rulefile}" |sed "s/${VersionFromrule14m}/${buildVersion}/g" > "${Rules}/${modifiedrulefile}"
echo "-->Intall Version Section";cat "${Rules}/${modifiedrulefile}" |awk '/<package./,/<\/package>/'|sed 's/<\/package>/<\/package>\'$'\n/g'|sed 's/^$/-->Begin Upgrade Section/g'|sed '$d'
fi
}


#===================================================================
uninstallQaToolsPackage()
#===================================================================
{
echo -e "====================================================================================="
echo -e "Attempting to Delete Qa Tools Packages"
if [ -d /qa_bin/ ]; then
/usr/bin/expect -c '
spawn sudo /qa_bin/QaToolsUninstall.sh
expect {
 -re "sword" {
 exp_send "'"${machinepassword}\r"'"
 exp_continue
 }
 -re  "This will uninstall Meter crash reporter and qa tools from the machine. Proceed.. y ?" {
 exp_send "y\r"
 }
   }
  interact'
echo -e "LOG: Qa Tools Packages Deleted"
echo -e "====================================================================================="
else
echo -e "LOG: Seems like Qa Tools Packages are not installed on this machine"
fi
}

#===================================================================
install-verifyContents-uninstall-Brands()
#===================================================================
{
#---InstallationOfBrands---#
ruleFileWithoutPli=$(echo "${modifiedrulefile}"|sed 's/.pli//g')
#for singleOSAItem in $(cat "${OSAList/[[:cntrl:]]/}"|grep -i "PermissionResearch")
for singleOSAItem in $(cat "${OSAList/[[:cntrl:]]/}")
{
bidPart=$(date|md5|head -c11)
bid="1jhduevHGFD${bidPart//[[:cntrl:]]/}"
echo -e "====================================================================================="
echo -e "Installing Brand:${singleOSAItem/[[:cntrl:]]/}:"
/usr/bin/expect -c '
spawn sudo "'"${Installers//[[:cntrl:]]/}/${singleOSAItem//[[:cntrl:]]/}_${buildVersion//[[:cntrl:]]/}"'" -install -o:0 -start -uninst:"'"${singleOSAItem//[[:cntrl:]]/}"'" -bid:"'"${bid//[[:cntrl:]]/}"'" -url:"'"http://rules-dev-new.securestudies.com/oss/${ruleFileWithoutPli//[[:cntrl:]]/}.asp?cur=${buildVersion//[[:cntrl:]]/}&os=mac2&osmajorver=10&lang=en-us&country=&test=1&ossname=${singleOSAItem//[[:cntrl:]]/}"'" 
expect {
  -re "sword" { 
  exp_send "'"${machinepassword}\r"'"
  exp_continue
  sleep 60
   }
  interact
  }'
sleep 120
#-----CheckingBrandisRunningOrNot---#
echo -e "====================================================================================="
echo -e "Checking Whether the Installed Brand is Running or Not:"
if [[ $(ps -aef | grep -i "${singleOSAItem/[[:cntrl:]]/}"|head -2|wc -l|sed -e 's/^[ \t]*//') -eq 2 ]]; then
echo "PASS: Brand:${singleOSAItem/[[:cntrl:]]/} is Running"
ps -aef | grep -i "${singleOSAItem/[[:cntrl:]]/}"
else
echo "FAIL: Brand:${singleOSAItem/[[:cntrl:]]/} is Not Running"
fi
echo -e "====================================================================================="

#lengthofSingelOSAItemPermission=$(echo "${singleOSAItem/[[:cntrl:]]/}"|grep -i "PermissionResearch")
#if [[ "${#lengthofSingelOSAItemPermission}" -ne 0 ]]; then
SecurityTests "${singleOSAItem/[[:cntrl:]]/}" >> "${securityTestResults//[[:cntrl:]]/}" 2>&1
#fi

#----VerifyContentsOfBrands----#
echo -e "====================================================================================="
echo -e "Verifying Contents Of Brand:${singleOSAItem/[[:cntrl:]]/}:"
for singleFile in $(cat "${BrandFileList/[[:cntrl:]]/}")
do
command=$(ls -al /Applications/"${singleOSAItem/[[:cntrl:]]/}"/"${singleFile/[[:cntrl:]]/}" 2>/dev/null)
if [[ -n "${command}" ]]; then
echo "PASS: ${command} exists"
else
#echo "FAIL: ${command} Does not exist"
echo "FAIL: /Applications/${singleOSAItem/[[:cntrl:]]/}/${singleFile/[[:cntrl:]]/} Does not exist"
fi
done
#----UninstallBrands----#
echo -e "====================================================================================="
echo -e "Uninstalling Brand:${singleOSAItem/[[:cntrl:]]/}:"
if [ -d /Applications/"${singleOSAItem/[[:cntrl:]]/}" ]; then
/usr/bin/expect -c '
spawn sudo rm -rf "'"/Applications/${singleOSAItem/[[:cntrl:]]/}"'"
expect {
 -re "sword" {
 exp_send "'"${machinepassword}\r"'"
 exp_continue
 }
 interact
    }'
echo -e "PASS: Brand:${singleOSAItem/[[:cntrl:]]/} Uninstalled"
echo -e "======================================================================================"
else
echo -e "FAIL: Brand:${singleOSAItem/[[:cntrl:]]/} Seems like there is a problem with Uninstallation"
fi
}
}
#==================================================================
checkPassFail()
#==================================================================
{
echo -e "======================================================================================"
NumberofPassFromResultsFile=$(cat "${Results}"|grep -i "PASS:"|wc -l)
NumberofFailsFromResultsFile=$(cat "${Results}"|grep -i "FAIL:"|wc -l)


if [[ "${NumberofPassFromResultsFile}" -eq  "${NumberofPassExpected}" ]]; then
echo "Total Number of PASS from ${Results} is EQUAL to Expected Number i.e: ${NumberofPassExpected}"
else
echo "Total Number of PASS from ${Results} is Not EQUAL to Expected Number."
echo "PASS from File:${NumberofPassFromResultsFile} and Expected PASS:${NumberofPassExpected}"
fi

if [[ "${NumberofFailsFromResultsFile}" -eq  "${NumberofFailExpected}" ]]; then
echo "Total Number of FAIL from ${Results} is EQUAL to Expected Number i.e: ${NumberofFailExpected}"
else
echo "Total Number of FAIL from ${Results} is NOT EQUALto Expected Number."
echo "FAIL from File:${NumberofFailsFromResultsFile} and Expected FAIL:${NumberofFailExpected}"
fi

}

#==================================================================
SecurityTests()
#==================================================================
{
item=$(echo "${1}")
echo -e "+++===============================================================================+++"
echo -e "SecutiryTestResults: BRAND ---> ${item/[[:cntrl:]]/}"
echo -e "=====================================================================================" 
echo -e "SecurityTest: Scenario 1(Row - 4) --> /Applications/${item/[[:cntrl:]]/} Contents" 
ls -al /Applications/"${item/[[:cntrl:]]/}" 
echo -e "=====================================================================================" 
echo -e "SecurityTest: Scenario 2(Row - 5) --> /Applications/${item/[[:cntrl:]]/}/csproxy Contents" 
ls -al /Applications/"${item/[[:cntrl:]]/}"/csproxy 
echo -e "=====================================================================================" 
echo -e "SecurityTest: Scenario 3(Row - 6) --> This should be manually Completed. Please follow Test Plan."
echo -e "====================================================================================="
echo -e "=====================================================================================" 
echo -e "SecurityTest: Scenario 4(Row - 5) --> Please look at Test Plan and search for Files in OSAAutomationResults Email"
echo -e "====================================================================================="
echo -e "SecurityTest: Scenario 5(Row - 8) --> Contents of *.xml" 
echo -e "Without sudo:"; less /Applications/"${item//[[:cntrl:]]/}"/rule7.xml
echo -e "With sudo:"
expect_command=$(/usr/bin/expect -c '
spawn sudo cat "'"/Applications/${item//[[:cntrl:]]/}/rule35.xml"'"  
expect {
  -re "sword" { 
  exp_send "'"${machinepassword}\r"'"
  exp_continue
  sleep 5
   }
  interact
  }')
  echo -e "${expect_command}" 
sleep 2
echo -e "====================================================================================="
echo -e "SecurityTest: Scenario 6(Row - 9) --> Contents of *.dat" 
echo -e "Without sudo:"; less /Applications/"${item//[[:cntrl:]]/}"/csproxy/csp_config_dev.dat
echo -e "With sudo:"
expect_command=$(/usr/bin/expect -c '
spawn sudo cat "'"/Applications/${item//[[:cntrl:]]/}/csproxy/csp_config_dev.dat"'"  
expect {
  -re "sword" { 
  exp_send "'"${machinepassword}\r"'"
  exp_continue
  sleep 5
   }
  interact
  }')
  echo -e "${expect_command}" 
sleep 2
echo -e "====================================================================================="
#echo -e "SecurityTest: Scenario 6(Row - 9) --> Contents of *.log" 
#echo -e "Without sudo:";less /Applications/"${item//[[:cntrl:]]/}"/csproxy/csproxy_access.log
#echo -e "With sudo:"
#expect_command=$(/usr/bin/expect -c '
#spawn sudo cat "'"/Applications/${item//[[:cntrl:]]/}/csproxy/csproxy_access.log"'"  
#expect {
 # -re "sword" { 
 # exp_send "'"${machinepassword}\r"'"
 # exp_continue
 # sleep 5
 #  }
 # interact
 # }')
#  echo -e "${expect_command}" 
#sleep 2
#echo -e "====================================================================================="
echo -e "SecurityTest: Scenario 7(Row - 10) --> Contents of .<BrandName>rg" 
echo -e "Without sudo:";less /Applications/"${item//[[:cntrl:]]/}/.${item//[[:cntrl:]]/}rg"
echo -e "With sudo:"
expect_command=$(/usr/bin/expect -c '
spawn sudo cat "'"/Applications/${item//[[:cntrl:]]/}/.${item//[[:cntrl:]]/}rg"'"  
expect {
  -re "sword" { 
  exp_send "'"${machinepassword}\r"'"
  exp_continue
  sleep 5
   }
  interact
  }')
  echo -e "${expect_command}" 
sleep 2
echo -e "====================================================================================="
echo -e "SecurityTest: Scenario 8(Row - 11) --> Statically Link Liberaries" 
expect_command=$(/usr/bin/expect -c '
spawn /usr/bin/otool -L "'"/Applications/${item//[[:cntrl:]]/}/${item//[[:cntrl:]]/}.app/Contents/MacOS/${item//[[:cntrl:]]/}"'"  
expect {
  -re "sword" { 
  exp_send "'"${machinepassword}\r"'"
  exp_continue
  sleep 5
   }
  interact
  }')
  echo -e "${expect_command}" 
sleep 2
 echo -e "====================================================================================="
echo -e "SecurityTest: Scenario 8(Row - 11) --> Statically Link Liberaries" 
expect_command=$(/usr/bin/expect -c '
spawn /usr/bin/otool -L "'"/Applications/${item//[[:cntrl:]]/}/${item//[[:cntrl:]]/}.app/Contents/Resources/${item//[[:cntrl:]]/}D.app/Contents/MacOS/${item//[[:cntrl:]]/}D"'"  
expect {
  -re "sword" { 
  exp_send "'"${machinepassword}\r"'"
  exp_continue
  sleep 5
   }
  interact
  }')
  echo -e "${expect_command}" 
sleep 2
echo -e "====================================================================================="
echo -e "SecurityTest: Scenario 9(Row - 12) --> This should be manually Completed. Please follow Test Plan."
echo -e "=====================================================================================\n\n\n"
}
#==================================================================
# the actual script
#===================================================================
prepare_environment
Main > "${Results}"
checkPassFail >> "${Results}"
email_results "${securityTestResults}" "${email_addresses}" "${security_test_email_subject}"
email_results "${Results}" "${email_addresses}" "${email_subject}"
cleanup

