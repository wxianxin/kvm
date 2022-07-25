#!/bin/bash
# Steven 20200702

# Print commands and their arguments as they are executed.
set -x

# # Kill wayland display manager
# sudo systemctl stop display-manager.service

for device in $(lspci | grep -e Radeon -e 'Navi 2' | awk '{print "0000:"$1}')
do
    echo "$device"
    sudo bash -c "echo -n $device > /sys/bus/pci/devices/$device/driver/unbind"
done

# When the motherboard treat your GPU (the one that you try to assign for vm) as the primary GPU, you will have difficulties to unbind it completely, and the following 3 lines fix the issue mentioned in the link below
# https://www.redhat.com/archives/vfio-users/2016-March/msg00088.html
sudo bash -c "echo 0 > /sys/class/vtconsole/vtcon0/bind"
sudo bash -c "echo 0 > /sys/class/vtconsole/vtcon1/bind"
# sudo bash -c "echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind"

sleep 2

# sudo modprobe -r amdgpu

sudo modprobe vfio
sudo modprobe vfio-pci
# sudo modprobe vfio_iommu_type1

sudo bash -c "echo 1002 73df > /sys/bus/pci/drivers/vfio-pci/new_id"
sudo bash -c "echo 1002 ab28 > /sys/bus/pci/drivers/vfio-pci/new_id"

echo "---- Steven ---- GPU rebound to vfio-pci ----"

# # start wayland display manager
# sudo systemctl start display-manager.service

# sudo bash -c "echo -n 0000:01:00.0 > /sys/bus/pci/devices/0000:01:00.0/driver/unbind"
# sudo bash -c "echo vfio-pci > /sys/bus/pci/devices/0000:01:00.0/driver_override"
# sudo bash -c "echo 0000:01:00.0 > /sys/bus/pci/drivers/vfio-pci/bind"
