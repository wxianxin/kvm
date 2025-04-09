#!/bin/bash
for c in {0..9} {16..25}; do
  echo 1800000 | sudo tee /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq
  maxf=$(cat /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq)
  echo "cpu${c}: $((maxf/1000)) MHz"
done
