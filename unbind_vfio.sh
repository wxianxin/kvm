#!/bin/bash

# set -x

modprobe vfio
modprobe vfio-pci
modprobe vfio_iommu_type1

gpu="0000:01:00.0"
aud="0000:01:00.1"
gpu_vd="$(cat /sys/bus/pci/devices/$gpu/vendor) $(cat /sys/bus/pci/devices/$gpu/device)"
aud_vd="$(cat /sys/bus/pci/devices/$aud/vendor) $(cat /sys/bus/pci/devices/$aud/device)"
echo $gpu_vd
echo $aud_vd

# " > /dev/null" -> suppresses the standard output of tee
function bind_vfio {
  echo "$gpu" | sudo tee "/sys/bus/pci/devices/$gpu/driver/unbind" > /dev/null
  echo "$aud" | sudo tee "/sys/bus/pci/devices/$aud/driver/unbind" > /dev/null
  echo "$gpu_vd" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null
  echo "$aud_vd" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id > /dev/null
}

function unbind_vfio {
  echo "$gpu_vd" | sudo tee /sys/bus/pci/drivers/vfio-pci/remove_id > /dev/null
  echo "$aud_vd" | sudo tee /sys/bus/pci/drivers/vfio-pci/remove_id > /dev/null
  echo 1 | sudo tee "/sys/bus/pci/devices/$gpu/remove" > /dev/null
  echo 1 | sudo tee "/sys/bus/pci/devices/$aud/remove" > /dev/null
  echo 1 | sudo tee "/sys/bus/pci/rescan" > /dev/null
}

unbind_vfio
