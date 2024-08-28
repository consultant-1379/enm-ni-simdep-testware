#!/usr/bin/python

######################################################################################
#     File Name     : runCliCommand.py
#     Author        : Sneha Srivatsav Arra
#     Description   : To run cli commands on ENM GUI
#     Date Created  : 09 Aug 2017
#######################################################################################
#
import enmscripting
import sys

params=sys.argv[1:]
command=params[0]
ENM_URL=params[1]

print "Executing " + command

enmSession=enmscripting.open(ENM_URL, "Administrator", "TestPassw0rd")
enmCmd=enmSession.command()

if len(params)==2:
    response=enmCmd.execute(command)
elif len(params)==3:
    file_path=params[2]
    response=enmCmd.execute(command, open(file_path,"r"))
elif len(params)==4:
    download_file=params[3]
    response=enmCmd.execute(command)

if response.has_files():
     for enm_file in response.files():
         print('File Name: ' + download_file)
         enm_file.download(download_file)
         exit(0)

output=tuple(response.get_output())
final_out=[]
for tupl in output:
    if isinstance(tupl,tuple):
        for element in tupl:
                final_out.append(str(element).replace(",","\t").strip(")").strip("("))
    else:
        final_out.append(str(tupl))
for item in final_out:
    print item

if "Command syntax error" in str(output):
    print "Error in command"
    exit(1)

enmscripting.close(enmSession)

