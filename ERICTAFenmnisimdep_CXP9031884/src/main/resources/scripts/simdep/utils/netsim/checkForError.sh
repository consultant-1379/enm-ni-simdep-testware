#/bin/sh
ERROR_CODE=$1
FILE_NAME=$2
#echo "The error code is $ERROR_CODE\n";
#echo "The file name  $FILE_NAME\n";
if egrep -i "$ERROR_CODE" $FILE_NAME >> /dev/null
then echo 1
else echo 0
fi
