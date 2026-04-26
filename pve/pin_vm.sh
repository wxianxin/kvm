#!/bin/bash
PCPUS=(0 1 2 3 4 5 6 7)
QPID=$(cat /var/run/qemu-server/101.pid)

TIDS=($(for tid in /proc/$QPID/task/*; do
    name=$(cat $tid/comm 2>/dev/null)
    [[ $name == CPU\ */KVM ]] && basename $tid
done | sort -n))

echo "vCPU TIDs: ${TIDS[@]}"
for i in "${!TIDS[@]}"; do
    taskset -cp ${PCPUS[$i]} ${TIDS[$i]}
    echo "vCPU $i → pCPU ${PCPUS[$i]} (tid ${TIDS[$i]})"
done

sleep 10

# 强制启用 MSI
setpci -s 03:00.2 a2.w=0001
setpci -s 03:00.3 a2.w=0001
echo "MSI 强制启用完成"
