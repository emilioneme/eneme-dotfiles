#!/usr/bin/env bash

cpu=$(LC_ALL=C top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8; exit}')
cpu=${cpu:-0}
memory=$(free | awk '/^Mem:/ {print int($3/$2*100)}')
memory=${memory:-0}
load=$(cut -d' ' -f1 /proc/loadavg)
load=${load:-0.00}
disk=$(df -P / | awk 'NR == 2 {gsub(/%/, "", $5); print $5}')
disk=${disk:-0}
refresh=$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | select(.focused == true)][0].refreshRate // empty' | awk '{printf "%.0f", $1}')
refresh=${refresh:-N/A}

gpu=N/A
gpuTemperature=N/A
vram=N/A
if command -v nvidia-smi >/dev/null 2>&1; then
	IFS=',' read -r gpuValue temperatureValue memoryUsed memoryTotal <<< "$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n 1)"
	if [[ -n "$gpuValue" && -n "$temperatureValue" && -n "$memoryUsed" && -n "$memoryTotal" ]]; then
		gpu=$(awk '{print $1}' <<< "$gpuValue")
		gpuTemperature=$(awk '{print $1}' <<< "$temperatureValue")
		vram=$(awk -v used="$memoryUsed" -v total="$memoryTotal" 'BEGIN { if (total > 0) printf "%.0f", used / total * 100; else print "N/A" }')
	fi
fi

printf '%s,%s,%s,%s,%s,%s,%s,%s\n' "$cpu" "$memory" "$load" "$disk" "$refresh" "$gpu" "$gpuTemperature" "$vram"
