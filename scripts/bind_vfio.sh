#!/bin/bash
# Steven 20200702

# Print commands and their arguments as they are executed.
# set -x

# # Kill wayland display manager
# sudo systemctl stop display-manager.service

#!/bin/bash

pci_devices=(
    # "0000:03:00.0"  # GPU
    # "0000:03:00.1"  # Audio
    "0000:03:00.2"  # USB
    "0000:03:00.3"  # Serial (i2c)
)

# Preload vendor/device IDs
declare -A vd_ids
for dev in "${pci_devices[@]}"; do
    vd_ids[$dev]="$(cat /sys/bus/pci/devices/$dev/vendor) $(cat /sys/bus/pci/devices/$dev/device)"
done

unbind_consoles() {
    for vt in /sys/class/vtconsole/vtcon*; do
        [ -e "$vt" ] || continue
        name="$(< "$vt/name")"
        if grep -qi "frame buffer" <<< "$name"; then
            echo "Unbinding $vt ($name)"
            echo 0 | sudo tee "$vt/bind"
        fi
    done
    # sudo sh -c "echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind"
}

bind_vfio() {

    # Load required modules
    sudo modprobe vfio
    sudo modprobe vfio-pci
    sudo modprobe vfio_iommu_type1

    # Unbind host drivers, add to Vfio and bind
    for dev in "${pci_devices[@]}"; do
        echo "Unbinding $dev (${vd_ids[$dev]})"
        sudo sh -c "echo '$dev' > /sys/bus/pci/devices/$dev/driver/unbind"
    done

    unbind_consoles

    for dev in "${pci_devices[@]}"; do
        echo "Binding vfio $dev (${vd_ids[$dev]})"
        sudo sh -c "echo '${vd_ids[$dev]}' > /sys/bus/pci/drivers/vfio-pci/new_id"
        sudo sh -c "echo '$dev' > /sys/bus/pci/drivers/vfio-pci/bind"
        sudo sh -c "echo vfio-pci > /sys/bus/pci/devices/$dev/driver_override"
    done

    echo "---- Steven ---- All devices rebound to vfio-pci ----"
}

unbind_vfio() {

    # Remove vendor/device IDs from vfio-pci # usually not necessary 
    # for vd in "${vd_ids[@]}"; do
    #     sudo sh -c "echo '$vd' > /sys/bus/pci/drivers/vfio-pci/remove_id"
    # done 

    for dev in "${pci_devices[@]}"; do
        echo "Releasing $dev"
        sudo sh -c "echo '$dev' > /sys/bus/pci/devices/$dev/driver/unbind"
        # Remove devices from the PCI bus # Too strong, harder to attach
        # sudo sh -c "echo 1 > /sys/bus/pci/devices/$dev/remove"
    done

    # Rescan the PCI bus to rediscover devices
    sudo sh -c "echo 1 > /sys/bus/pci/rescan"
    echo "---- Steven ---- All devices unbound from vfio-pci ----"
}

case "$1" in
    bind)   bind_vfio ;;
    unbind) unbind_vfio ;;
    *)      echo "Usage: $0 {bind|unbind}" ;;
esac


# bind_vfio
# unbind_vfio


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
