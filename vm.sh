# Standard locations from the Ubuntu `ovmf` package; last one is arbitrary:
export VGAPT_FIRMWARE_BIN=/usr/share/OVMF/OVMF_CODE.fd
export VGAPT_FIRMWARE_VARS=/usr/share/OVMF/OVMF_VARS.fd
export VGAPT_FIRMWARE_VARS_TMP=/tmp/OVMF_VARS.fd.tmp


# cp -f $VGAPT_FIRMWARE_VARS $VGAPT_FIRMWARE_VARS_TMP &&
qemu-system-x86_64 \
  -drive if=pflash,format=raw,readonly,file=$VGAPT_FIRMWARE_BIN \
  -drive if=pflash,format=raw,file=$VGAPT_FIRMWARE_VARS_TMP \
  -enable-kvm \
  -machine q35,accel=kvm,mem-merge=off \
  -cpu host,kvm=off,hv_vendor_id=vgaptrocks,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time \
  -smp 8,sockets=1,cores=4,threads=2 \
  -m 8192 \
  -vga none \
  -rtc base=localtime \
  -serial none -parallel none \
  -usb -usbdevice host:046d:c539 -usbdevice host:0a12:0001 \
  -device virtio-scsi-pci,id=scsi \
  -device vfio-pci,host=01:00.0,multifunction=on \
  -device vfio-pci,host=01:00.1 \
  -drive file=/dev/sda,format=raw,if=virtio,cache=none,index=0 \
;


# -drive file=/home/xxxx/Win10_1803_English_x64.iso,media=cdrom \
# -drive file=/virtio-win-0.1.149.iso,media=cdrom \
# -net nic,model=virtio \