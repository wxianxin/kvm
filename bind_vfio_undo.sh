#! /bin/bash
# Steven 20220401

set -x

for device in $(lspci | grep Radeon | awk '{print "0000:"$1}')
do
    echo "$device"
    sudo bash -c "echo -n $device > /sys/bus/pci/devices/$device/driver/unbind"
done

sleep 2

sudo bash -c "echo 0000:03:00.0 > /sys/bus/pci/drivers/amdgpu/bind"
sudo bash -c "echo 0000:03:00.1 > /sys/bus/pci/drivers/snd_hda_intel/bind"
# sudo bash -c "echo 0000:01:00.2 > /sys/bus/pci/drivers/xhci_hcd/bind"
# sudo bash -c "echo 0000:01:00.3 > /sys/bus/pci/drivers/nvidia-gpu/bind"
sleep 2

modprobe -r vfio
modprobe -r vfio-pci

modprobe amdgpu

echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

