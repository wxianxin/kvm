#!/bin/bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo "schedutil" | sudo tee "$file" > /dev/null; done
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
