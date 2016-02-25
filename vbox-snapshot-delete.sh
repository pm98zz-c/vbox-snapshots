#!/bin/bash

# Takes snapshots of VirtualBox VMs.

# "Namespace" our snapshots.
PREFIX="vbox-snapshot-"

# Make sure we can reach the binary.
PATH="/opt/bin:/usr/local/bin:$PATH"
VBOX_MG=$(which VBoxManage)

# Display arguments options.
usage(){
  echo "$0 --keep <number>  --running || --poweroff"
  echo ""
  echo "Deletes older VirtualBox VMs snapshots:"
  echo "--keep: number of snapshots to keep"
  echo "Specify either:"
  echo "--running: only snapshots created while the VM was running"
  echo "--halted: only snapshots created while the VM was halted"
}

# Parse options
for ARGUMENT in $@
  do
   case "$ARGUMENT" in
    "--keep")
      shift
      KEEP_SNAPSHOTS="$1"
    ;;
    "--running")
      shift
      SUFFIX="running"
    ;;
    "--poweroff")
      shift
      SUFFIX="poweroff"
    ;;
   esac
done

# Verify arguments.
if [ -z "$KEEP_SNAPSHOTS" ] || [ -z "$SUFFIX" ] || ! [ "$KEEP_SNAPSHOTS" -eq "$KEEP_SNAPSHOTS" ] 2>/dev/null; then
  usage
  exit 1
fi

# Actually process deletion.
# @param $1 (string) VM ID
# @param $2 (string) Human name of the VM
deleteSnapshots(){
  NUM_SNAPSHOTS=$($VBOX_MG snapshot "$1" list | grep -c "$PREFIX$SUFFIX")
  if [ $(( $NUM_SNAPSHOTS - $KEEP_SNAPSHOTS )) -gt 0 ]; then
    # Delete a snapshot, they are listed from oldest to newest.
    SNAPSHOT_ID=$($VBOX_MG snapshot "$1" list | grep   -m 1 "$PREFIX$SUFFIX" | cut -d "(" -f 2 | cut -d " " -f 2 | cut -d ")" -f1)
    SNAPSHOT_NAME=$($VBOX_MG snapshot "$1" list | grep   -m 1 "$PREFIX$SUFFIX" | cut -d "(" -f 1 | cut -d ":" -f 2)
    echo "Deleting snapshot \"$SNAPSHOT_NAME\" ($SNAPSHOT_ID) for Virtual machine $2 ($1)"
    $VBOX_MG snapshot "$1" delete "$SNAPSHOT_ID"
    # See if we need to go on.
    deleteSnapshots "$1" "$2"
  fi
}

# List VMS and iterate.
VMS=$($VBOX_MG list vms | cut -d "{" -f2 | cut -d "}" -f1)

for VM_ID in $VMS;
do
  STATE_INFO=$($VBOX_MG showvminfo "$VM_ID" --machinereadable | grep "VMState=" | cut -d "\"" -f 2 | cut -d "\"" -f 1)
  # Skip running VMs, as we can't delete snapshots.
  if [ "$STATE_INFO" = "poweroff" ]; then
    VM_NAME=$($VBOX_MG showvminfo "$VM_ID" --machinereadable | grep "name=" | cut -d "\"" -f 2 | cut -d "\"" -f 1)
    deleteSnapshots "$VM_ID" "$VM_NAME"
  fi
done

exit 0