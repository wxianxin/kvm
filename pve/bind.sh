#!/usr/bin/env bash
set -euo pipefail

DEVICES=(
  "0000:03:00.2"
  "0000:03:00.3"
)

modprobe vfio-pci

for dev in "${DEVICES[@]}"; do
  echo "Processing $dev"

  # If currently bound, unbind first
  if [ -L "/sys/bus/pci/devices/$dev/driver" ]; then
    cur=$(basename "$(readlink "/sys/bus/pci/devices/$dev/driver")")
    echo "  Unbinding from $cur"
    echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind"
  fi

  # Force this device to use vfio-pci
  echo vfio-pci > "/sys/bus/pci/devices/$dev/driver_override"

  # Ask PCI core to reprobe and bind using the override
  echo "$dev" > /sys/bus/pci/drivers_probe
done

echo
lspci -nnk -s 03:00.2 -s 03:00.3
