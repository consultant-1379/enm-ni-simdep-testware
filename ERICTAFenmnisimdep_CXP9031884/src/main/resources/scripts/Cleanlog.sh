#!/bin/sh
days=$1
echo "INFO: Deleting log files which are present for more than "$days" day(s)"
rm -rf `find /netsim/inst/netsimprmn -type f -mtime +"$days" -printf '%p\t'`
rm -rf `find /netsim/inst/prmnresponse -type f -mtime +"$days" -printf '%p\t'`
cd /netsim/inst/logfiles/
rm -rf `ls /netsim/inst/logfiles/ | grep old* | grep -v old1`
OLD=`ls /netsim/inst/logfiles/ | grep old1`
for old in $OLD
do
   echo "file:$old"
   size=`du -s /netsim/inst/logfiles/$old | awk '{print $1}'`
   echo "size:$size"
   if [ $size -gt 20000 ]
   then
       echo "deleting file $old"
       rm /netsim/inst/logfiles/$old
   fi
done

delete() {
    size_in=$1
    if [[ -z $size_in ]]
    then
        echo "INFO: No crash dumps in server"
    elif [[ $size_in == *"K"* ]] || [[ $size_in == *"M"* ]]
    then
        echo "INFO: Total crash dumps size is in KB"
    elif [[ $size_in == *"G"* ]]
    then
        echo "INFO: Total crash dump size is $size_in"
        sizeNum=`echo $size_in | sed 's/[A-Z]//g'`
        if [[ $sizeNum > 2 ]]
        then
            rm -rf /netsim/inst/`ls -lrth /netsim/inst/ | grep 'erl_crash' | head -1 | rev | cut -d ' ' -f1 | rev`
            size1=`find /netsim/inst/ -type f -name 'erl_crash' -exec du -ch {} + | grep total$ | cut -f1`
            delete $size1
        else
            echo "INFO: Total crash dumps size is less then 2GB....Not Deleting Crash dumps"
        fi
    fi
}


days1=1

rm -rf `find /netsim/inst/ -type f -name 'erl_crash' -mtime +"$days1" -printf '%p\t'`

size=`find /netsim/inst/ -type f -name 'erl_crash' -exec du -ch {} + | grep total$ | cut -f1`

delete $size
