#!/bin/bash
# Steven 20200702

for device in $(lspci | grep NVIDIA | awk '{print "0000:"$1}')
do
    echo "$device"
    sudo bash -c "echo -n $device > /sys/bus/pci/devices/$device/driver/unbind"
    sudo bash -c "echo -n vfio-pci > /sys/bus/pci/devices/$device/driver_override"
    sudo bash -c "echo -n $device > /sys/bus/pci/drivers/vfio-pci/bind"
done

# sudo bash -c "echo -n 0000:01:00.0 > /sys/bus/pci/devices/0000:01:00.0/driver/unbind"
# sudo bash -c "echo vfio-pci > /sys/bus/pci/devices/0000:01:00.0/driver_override"
# sudo bash -c "echo 0000:01:00.0 > /sys/bus/pci/drivers/vfio-pci/bind"
