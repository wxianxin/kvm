#!/bin/bash
# In qemu command window, get vcpu process id by executing `info cpus`
# Then, use the first PID as the input to this script(assuming PIDs are in order)
# position parameter: $1 - PID, $2 starting CPU thread, $3 ending CPU thread

if [[ $# -eq 0 ]]
then
    echo "No positional parameter!"
    echo "e.g.: cpu_pining 1000 2 7"
    echo "PID:1000, starting CPU thread: 2, ending CPU thread: 7"
    exit
fi

echo "PID:" $1; echo "Thread Count:" $2

for i in $(seq $2 $3)
do
    sudo taskset -cp $i $(($1 + $i - $2));
    # chrt -f --pid 1 $(expr $PID + ( $i - 1 ));
done;

