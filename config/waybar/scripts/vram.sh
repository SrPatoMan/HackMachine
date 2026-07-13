#!/bin/bash
used=$(cat /sys/class/drm/card*/device/mem_info_vram_used 2>/dev/null | head -1)

if [ -n "$used" ]; then
    used_mb=$((used / 1024 / 1024))
    echo "${used_mb}MB"
else
    echo "N/A"
fi