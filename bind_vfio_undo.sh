for device in $(lspci | grep NVIDIA | awk '{print "0000:"$1}')
do
    echo "$device"
    sudo bash -c "echo -n $device > /sys/bus/pci/devices/$device/driver/unbind"
done

sudo bash -c "echo 0000:01:00.0 > /sys/bus/pci/drivers/nouveau/bind"
sudo bash -c "echo 0000:01:00.1 > /sys/bus/pci/drivers/snd_hda_intel/bind"
# sudo bash -c "echo 0000:01:00.2 > /sys/bus/pci/drivers/xhci_hcd/bind"
# sudo bash -c "echo 0000:01:00.3 > /sys/bus/pci/drivers/nvidia-gpu/bind"

