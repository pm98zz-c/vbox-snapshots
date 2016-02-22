#!/bin/bash

# Takes snapshots of VirtualBox VMs.

# "Namespace" our snapshots.
PREFIX="vbox-snapshot-"

# Display arguments options.
usage(){
  echo "$0 --running || --poweroff"
  echo ""
  echo "Takes snapshots of VirtualBox VMs, either:"
  echo "--running: only the VMs currently running/online"
  echo "--poweroff: only the VMs currently halted/offline"
}

# Check we have an argument.
if [ ! "$1" = "--running" ] && [ ! "$1" = "--poweroff" ]; then
  usage
  exit 1
fi

# Gather VMs informations.
ALL_VMS=$(VBoxManage list vms | cut -d "{" -f2 | cut -d "}" -f1)

# Just in case…
if [ -z "$ALL_VMS" ]; then
  echo "No information about VirtualBox VMs could be found."
  echo "Either you have no existing boxes or there is an issue with your VirtualBox setup."
  exit 1
fi


SUFFIX=${1/'--'/}

# Actually perform snapshot generation.
# @param $1 (string) VM ID
# @param $2 (string) Human name of the VM
takeSnapshotrunning(){
  echo "Taking a snapshot of Virtual machine $2 ($1) while in $SUFFIX mode."
  TIMESTRING=$(date -u '+%Y-%m-%dT%H:%M:%S')
  SNAPSHOT_NAME="$PREFIX$SUFFIX $TIMESTRING"
  VBoxManage snapshot "$1" take "$SNAPSHOT_NAME" || exit 1
}

# Performs a check on offline VMs
# and take a snapshot if needed.
# @param $1 (string) VM ID
# @param $2 (string) Human name of the VM
takeSnapshotpoweroff(){
  # Check if a snapshot already exists.
  CURRENT_SNAPSHOT=$(VBoxManage showvminfo "$1" --machinereadable | grep "CurrentSnapshotName=\"$PREFIX$SUFFIX" | cut -d "\"" -f 2 | cut -d "\"" -f 1)
  # if not, take one.
  if [ -z "$CURRENT_SNAPSHOT" ]; then
    takeSnapshotrunning "$1" "$2"
    return 0
  fi
  # Fetch and compare last changed state and date of current snapshot.
  SNAPSHOT_DATE=$(echo "$CURRENT_SNAPSHOT" | cut -d " " -f 2)
  LASTCHANGED_DATE=$(VBoxManage showvminfo "$1" --machinereadable | grep "VMStateChangeTime=" | cut -d "\"" -f 2 | cut -d "." -f 1)
  # BSD/Coreutils switch.
  date --version >/dev/null 2>&1
  if [ "$?" -eq "0" ]; then
    SNAPSHOT_TIMESTAMP=$(date --date="$SNAPSHOT_DATE" +%s)
    LASTCHANGED_TIMESTAMP=$(date --date="$LASTCHANGED_DATE" +%s)
  else
    SNAPSHOT_TIMESTAMP=$(date -jf "%Y-%m-%dT%H:%M:%S" "$SNAPSHOT_DATE" +"%s")
    LASTCHANGED_TIMESTAMP=$(date -jf "%Y-%m-%dT%H:%M:%S" "$LASTCHANGED_DATE" +"%s")
  fi
  # Changed since last snapshot.
  if [ $LASTCHANGED_TIMESTAMP -gt $SNAPSHOT_TIMESTAMP ]; then
    takeSnapshotrunning "$1" "$2"
    return 0
  fi
  # echo "Virtual machine $2 ($1) has not changed since last snapshot, skipping it."
  return 0
}

# Iterate over the VMs list.
# While we could query running VMS only and "substract"
# them from $ALL_VMS for halted, 
# doing it for each one separately minimize the cases
# where state has changed in between state check
# and actual snapshot taking.
for VM_ID in $ALL_VMS;
do
  STATE_INFO=$(VBoxManage showvminfo "$VM_ID" --machinereadable | grep "VMState=" | cut -d "\"" -f 2 | cut -d "\"" -f 1)
  if [ "$STATE_INFO" = "$SUFFIX" ]; then
    VM_NAME=$(VBoxManage showvminfo "$VM_ID" --machinereadable | grep "name=" | cut -d "\"" -f 2 | cut -d "\"" -f 1)
    SNAP_COMMAND="takeSnapshot$SUFFIX"
    $SNAP_COMMAND "$VM_ID" "$VM_NAME"
  fi
done

exit 0