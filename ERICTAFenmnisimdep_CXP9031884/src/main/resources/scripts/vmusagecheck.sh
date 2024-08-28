#!/bin/bash
prmn_log_check(){
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
NC='\033[0m'
yd=$(date  --date="yesterday" +"%Y%m%d")
d="$(date +'%Y%m%d')"
cd /var
threshold=$(cat VMUsageThreshold.txt)
echo "Threshold value is set to $threshold"
ls /netsim/inst/ # check if netsim is installed or not
if [[ $? -eq 0 ]] #netsim installed check 
then
echo -e "Netsim installed, checking further"
ls /netsim/inst/netsimprmn/ | grep $yd | grep .data > list.txt 
if [[ $? -eq 0 ]]
then
prmn_list=$(tac list.txt)
echo -e "PRMN LIST BEING SCANNED:\n $prmn_list \n ==============================================================="
count=0
breakPoint=0
cd /netsim/inst/netsimprmn
rm -rf vmprmn.txt
rm -rf accumulator.txt
rm -rf vmLoad.txt
for file in $prmn_list ## For loop 1 starts
do
sed '1d' $file > vmprmn.txt
cut -d"," -f2- vmprmn.txt >> accumulator.txt
done # # For loop 1 closed
cut -d"," -f4 --complement accumulator.txt > vmLoad.txt
vmload=$(sed -e 's/,/\n/g' vmLoad.txt | awk 'BEGIN {total=0} {total += $1} END {print total}')
echo "Todays Date: $yd , Todays VM Load: $vmload" >> /var/vmLoadHistory.txt
echo "VMLoad is $vmload"

if [[ $vmload == "0" ]]  # If case 1 starts 
then
###VM NOT IN USE !
#logic to increment vmutilization of value in it is greater than 0. else create a new file with value 1.
echo -e "\n ${BLUE} VM  is not actively used. ${NC}" 
ls /var/ | grep vmutilization.txt
if [[ $? -eq 0 ]] #If case 1.1
then

output=$(cat /var/vmutilization.txt)
if [[ $output -ge 0 ]] #If case 1.1.1
then
output=$((output+1))
echo "$output" > /var/vmutilization.txt
else
echo "do nothing" #lesser than zero case, nothing to be done.
fi # If case 1.1.1 closed
else
echo "1" > /var/vmutilization.txt
fi # If case 1.1 closed
#Check vm load value.
ls /var/ | grep vmUsageLoad.txt
if [[ $? -eq 0 ]] # If case 1.3 starts
then
output=$(cat /var/vmUsageLoad.txt)
output=$((output+1))
echo "$output" > /var/vmUsageLoad.txt
else
echo "1" > /var/vmUsageLoad.txt
fi
else
###VM IN USE !
echo -e "\n ${GREEN} RESULT : VM is actively used. ${NC}"
ls /var/ | grep vmutilization.txt
if [[ $? -eq 0 ]] # If case 1.2 starts
then
echo "0" > /var/vmutilization.txt
else
echo "0" > /var/vmutilization.txt
fi #if case 1.2 ends
## Check vm load value and compare with threshold value.
ls /var/ | grep vmUsageLoad.txt
if [[ $? -eq 0 ]] # If case 1.4 starts
then
output=$(cat /var/vmUsageLoad.txt)
else
echo "0" > /var/vmUsageLoad.txt
output=$(cat /var/vmUsageLoad.txt)
fi #If case 1.4 closed.
if [[ $vmload -le $threshold ]] #If case 1.4 part 2
then
output=$((output+1))
echo "$output" > /var/vmUsageLoad.txt
else
echo "0" > /var/vmUsageLoad.txt 
fi # If case 1.4 part 2 closed.
fi #If case 1.4 closed
fi        # if case 1 ends
cd -
else
echo -e "\n ******************** RESULT FOR VM  *************************** "
echo -e "${RED} Netsim is not installed. Reclaim . ${NC}" 
echo -e "\n ************************************************************************ "
fi #netsim installed check if case closed
}
prmn_log_check


