#!/bin/bash

restore_cpu_freq="yes"
release_hugepage="yes"
restore_cpu_pinning="yes"
reverse_rebind_gpu="yes"

source /home/$LOGNAME/kvm/scripts/set_cpu_performance.sh
source /home/$LOGNAME/kvm/scripts/bind_vfio.sh

if [ "$restore_cpu_freq" == "yes" ]; then
    echo "set_cpu_performance_max: $restore_cpu_freq"
    set_cpu_maxp
fi

if [ "$release_hugepage" == "yes" ]; then
    echo "release_hugepage: $release_hugepage"  
    sudo sysctl vm.nr_hugepages=0
    sudo umount /dev/hugepages
fi

if [ "$restore_cpu_pinning" == "yes" ]; then
    sudo systemctl set-property --runtime -- user.slice AllowedCPUs=0-31
    sudo systemctl set-property --runtime -- system.slice AllowedCPUs=0-31
    sudo systemctl set-property --runtime -- init.scope AllowedCPUs=0-31
fi

if [ "$reverse_rebind_gpu" == "yes" ]; then
    echo "reverse_rebind_GPU: $reverse_rebind_gpu"
    unbind_vfio
fi
