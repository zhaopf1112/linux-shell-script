#!/bin/bash
#v1.0
#自动扩展lvm下的文件系统

set -e 

#[ ! -f /usr/bin/growpart ]&&yum -y install  cloud-utils cloud-utils-growpart

LV_Path="`df -h|awk '$6=="/"{print $1}'`"
LV_Name="`echo ${LV_Path##*/}|awk -F'-' '{print $2}'`"
VG_Name="`echo ${LV_Path##*/}|awk -F'-' '{print $1}'`"
PV_Name="`pvdisplay|grep -B 1 "${VG_Name}"|awk '/PV Name/{print $3}'`"
Disk_Name="`echo ${PV_Name##*/}|sed 's/[0-9]\+//'`"
Partition_Num="`echo ${PV_Name##*/}|sed 's/[a-zA-Z]\+//'`"

if [ "${Disk_Name}" ]&&[ "${Partition_Num}" ];then
    growpart /dev/${Disk_Name} ${Partition_Num}
else 
    [ "${Disk_Name}" ]||echo "Disk_Name is null"
    [ "${Partition_Num}" ]||echo "Disk_Name is null"
    exit 1
fi

if [ "${PV_Name}" ];then
    pvresize ${PV_Name}
else 
    echo "PV_Name is null"
    exit 1 
fi

if [ "${LV_Path}" ];then
    lvextend -l +100%FREE -r ${LV_Path}
else
    echo "LV_Path is null"
    exit 1
fi
    
echo "resize is successed"

