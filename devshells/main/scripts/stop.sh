#!/usr/bin/env bash

# Check for argument
if [ -z "$1" ]; then
  echo "Usage: $0 <vm-name>"
  exit 1
fi

VM_NAME="$1"

# Find PIDs of QEMU instances with the exact -name argument
mapfile -t PIDS < <(
  ps aux | grep '[q]emu-system' | grep -w "\-name $VM_NAME" | awk '{print $2}'
)

NUM_PIDS=${#PIDS[@]}

if [ "$NUM_PIDS" -eq 0 ]; then
  echo "No running VM found with name: $VM_NAME"
  exit 1
elif [ "$NUM_PIDS" -gt 1 ]; then
  echo "Multiple VMs found with name: $VM_NAME"
  printf 'Matched PIDs: %s\n' "${PIDS[@]}"
  echo "Please write valid unique VM name."
  exit 1
fi

PID="${PIDS[0]}"
echo "Stopping VM '$VM_NAME' with PID $PID..."
kill "$PID"
