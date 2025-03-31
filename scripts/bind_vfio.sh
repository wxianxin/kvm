#!/bin/bash
# Steven 20200702

# Print commands and their arguments as they are executed.
set -x

# # Kill wayland display manager
# sudo systemctl stop display-manager.service

pci_devices=(
    "0000:03:00.0"  # GPU
    "0000:03:00.1"  # Audio
    "0000:03:00.2"  # USB
    "0000:03:00.3"  # Serial
)
vd_ids=()
for dev in "${pci_devices[@]}"; do
    vd_ids+=("$(cat /sys/bus/pci/devices/$dev/vendor) $(cat /sys/bus/pci/devices/$dev/device)")
done

echo $ser_vd

bind_vfio() {
    for dev in "${pci_devices[@]}"; do
        sudo sh -c "echo '$dev' > /sys/bus/pci/devices/$dev/driver/unbind"
    done

    sudo modprobe vfio vfio-pci vfio_iommu_type1

    sudo sh -c "echo 0 > /sys/class/vtconsole/vtcon0/bind"
    sudo sh -c "echo 0 > /sys/class/vtconsole/vtcon1/bind"
    # sudo sh -c "echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind"

    for vd in "${vd_ids[@]}"; do
        sudo sh -c "echo '$vd' > /sys/bus/pci/drivers/vfio-pci/new_id"
    done

    echo "---- Steven ---- All devices rebound to vfio-pci ----"
}

bind_vfio

# for device in $(lspci | grep -e 7444 -e 'Navi 31' | awk '{print "0000:"$1}')
# do
#     echo "$device"
#     sudo bash -c "echo -n $device > /sys/bus/pci/devices/$device/driver/unbind"
# done

# sudo modprobe -r amdgpu
# sleep 5

# When the motherboard treat your GPU (the one that you try to assign for vm) as the primary GPU, you will have difficulties to unbind it completely, and the following 3 lines fix the issue mentioned in the link below
# https://www.redhat.com/archives/vfio-users/2016-March/msg00088.html

# # start wayland display manager
# sudo systemctl start display-manager.service

# sudo bash -c "echo -n 0000:01:00.0 > /sys/bus/pci/devices/0000:01:00.0/driver/unbind"
# sudo bash -c "echo vfio-pci > /sys/bus/pci/devices/0000:01:00.0/driver_override"
# sudo bash -c "echo 0000:01:00.0 > /sys/bus/pci/drivers/vfio-pci/bind"
