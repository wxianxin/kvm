########################################################################################
# compile QEMU
./configure --target-list=x86_64-softmmu --enable-libusb

########################################################################################
# UEFI setup
1. enable virtualization (usually enabled by default)
2. disable Smart Access Memory for VFIO GPU (Sometimes called CAM in UEFI)
########################################################################################
# Install necessary packages
sudo apt install qemu-kvm
sudo apt install ovmf
# Fedora has them installed by default
########################################################################################
# Archlinux
sudo pacman -S qemu-desktop # qemu x86 only
# If using systemd-resolved, add DNS entry to /etc/resolv.conf
#     nameserver 1.1.1.1
########################################################################################
# Kernel parameter

sudo vim /etc/default/grub
    GRUB_CMDLINE_LINUX_DEFAULT=”quiet intel_iommu=on”
sudo update-grub

# Fedora & AMD
sudo grubby --update-kernel=ALL --args="amd_iommu=on"
sudo vim /etc/default/grub
    amd_iommu=on iommu=pt rd.driver.pre=vfio-pci
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg 

# reboot and check
sh list_iommu_group.sh

########################################################################################
# CPU isolation
## Very good guide: https://www.suse.com/c/cpu-isolation-practical-example-part-5/
## ? No need to pass the “rcu_nocbs=” kernel parameter as that is automatically taken care of while passing the “nohz_full=” parameter.
## Using 'isolcpus=' is not advised because the isolation configuration can’t be later changed on runtime. This is why “isolcpus” tends to be considered as “deprecated” despite it being still in use. It may remain useful with specialized or embedded kernels that haven’t been built with cpusets/cgroups support. 
## At a lower level, it is also possible to affine each individual task to the desired set of CPUs using tools like taskset or relying on APIs like sched_setaffinity().  On a setup without cpusets support, it has the advantage to allow for affinity change on runtime, unlike what “isolcpus” does. The drawback is that it requires more finegrained work.

sudo vim /etc/default/grub
    GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet intel_iommu=on iommu=pt isolcpus=2-N nohz_full=2-N"


########################################################################################
# prevent the default driver to bind to the graphics card. # OR unbind driver before passthrough
########
sudo vim /etc/default/grub
    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt isolcpus=4-15 nohz_full=4-15 rcu_nocbs=4-15 module_blacklist=nouveau nouveau.modeset=0 vfio-pci.ids=10de:249d,10de:228b"
    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash intel_iommu=on iommu=pt isolcpus=0-7,16-23 nohz_full=0-7,16-23 rcu_nocbs=0-7,16-23 kvm.ignore_msrs=1 module.blacklist=amdgpu vfio-pci.ids=1002:744c,1002:ab30"

sudo grub-mkconfig -o /boot/grub/grub.cfg (or sudo update-grub; or sudo update-initramfs -u)

# Parameters like vfio-pci.ids passed via the kernel command line are only effective if the driver is built directly into the kernel (built-in), not if it's compiled as a module.
# Not all Linux distributions support the rd.driver.pre= parameter. It is commonly supported in distributions that use Dracut for initramfs generation (like Fedora, CentOS, RHEL).

########################################################################################
# Loading vfio-pci early

# /etc/modprobe.d/vfio.conf
softdep drm pre: vfio-pci
## if nvidia proprietary driver
softdep nvidia pre: vfio-pci

# NVIDIA: To dynamically bind/unbind NVIDIA driver -> ALWAYS boot with VFIO first, then bind to NVIDIA driver if necessary
# /etc/mkinitcpio.conf

MODULES=(... vfio_pci vfio vfio_iommu_type1 ...)

sudo mkinitcpio -P
###############################
# old
VGAPT_VGA_ID=10de:2484
VGAPT_AUDIO_ID=10de:228b
sudo bash -c "echo options vfio-pci ids=$VGAPT_VGA_ID,$VGAPT_AUDIO_ID > /etc/modprobe.d/vfio.conf"
sudo bash -c "echo vfio > /etc/modules-load.d/vfio.conf"
sudo bash -c "echo vfio-pci > /etc/modules-load.d/vfio-pci.conf"
# Fedora needs one more:
sudo bash -c "echo 'vfio_iommu_type1' > /etc/modules-load.d/vfio_iommu_type1.conf"

################################################################
# Windows BSOD "SYSTEM THREAD EXCEPTION NOT HANDLED"
echo 1 > /sys/module/kvm/parameters/ignore_msrs
# or permanently, use either one of the following 2 changes
    # kernel parameter
    kvm.ignore_msrs=1
    # modprobe.d file
    sudo bash -c "echo 'options kvm ignore_msrs=1' > /etc/modprobe.d/kvm.conf"
# To prevent clogging up dmesg with "ignored rdmsr" messages, additionally add
sudo bash -c "echo 'options kvm report_ignored_msrs=0' >> /etc/modprobe.d/kvm.conf"
################################################################
# reboot and check what driver is being used
lspci -knn

########################################################################################
# Finally
bash vm.sh


########################################################################################
# Performance Tuning
########################################################################################
watch -n.5 "cat /proc/cpuinfo | grep \"^[c]pu MHz\""
# hugepage
# vm.nr_hugepages should be a bit larger than necessary e.g. 8200*2 > 16384
mount -t hugetlbfs hugetlbfs /dev/hugepages
sysctl vm.nr_hugepages=8200
# qemu -m 16384 -mem-prealloc -mem-path /dev/hugepages 

# CPU pinning
# check CPU topology
lscpu -e
lstopo
# CPU pinning using taskset
# 1111111111000000=0xFFC0 (binary is reverse of the sequence of cpu id)
taskset 0xFFC0 qemu-system-x86_64 \blabla

# OVMF screen resolution
# Need to `ESC` during `Tianocore` UEFI screen, set resolution, then `reset`
