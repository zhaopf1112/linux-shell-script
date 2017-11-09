#!/bin/bash

# 2016/11/25
# Notice: Only work for CentOS7.1 image
# 
fdisk /dev/vda <<EOF
n
p



t

8e
w
EOF
partprobe
sync
mkfs -t ext3 /dev/vda3 
pvcreate /dev/vda3 -y
vgextend VolGroup00 /dev/vda3
lvdisplay
lvextend -l +100%FREE -r /dev/VolGroup00/lv_root 
resize2fs /dev/VolGroup00/lv_root 
