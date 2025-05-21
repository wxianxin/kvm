#!/bin/bash

set_cpu_lp() {
  for c in {0..31}; do
    echo 3000000 | sudo tee /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq
    maxf=$(cat /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq)
    echo "cpu${c}: $((maxf/1000)) MHz"
  done
}

set_cpu_hp() {
  for c in {0..31}; do
    echo 5752000 | sudo tee /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq
    # echo 1800000 | sudo tee /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq
    maxf=$(cat /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq)
    echo "cpu${c}: $((maxf/1000)) MHz"
  done
}

set_cpu_maxp() {
  for c in {0..31}; do
    default_max=$(cat /sys/devices/system/cpu/cpu${c}/cpufreq/cpuinfo_max_freq)
    echo "$default_max" | sudo tee /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq
    current_max=$(cat /sys/devices/system/cpu/cpu${c}/cpufreq/scaling_max_freq)
    echo "cpu${c}: $((current_max/1000)) MHz"
  done
}

