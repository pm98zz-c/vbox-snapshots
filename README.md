# vbox-snapshots
###### Yet another VirtualBox snapshotting script \o/
Simple bash scripts allowing to take/delete snapshots of VirtualBox machines. They are meant to be triggered by cron tasks and are targetted at boxes used as local development environments.
They were made to allow separate workflows for:
- snapshots of your currently running/online project VMS to be able to quickly revert to a previous step in case of mistakes (eg you replaced your WIP database with a fresh dump to test a merge request, then realized your own changes were not exported to code)
- snapshots of halted/offline VMS for longer terms projects/backups

## vbox-snapshot.sh
Takes the snapshots, only takes one argument, either
  --running
  takes snapshots of currently running VMs
  --poweroff
  takes snapshots of currently halted VMs
  
## vbox-snapshot.sh
Delete the snapshots, takes two arguments
  --keep <number>
  number of snapshots to keep
  --running || --poweroff
  either deletes snapshots that were taken when the VMs was running or powered off (not related to the 'current' state of the VM)

### Crontab example
```
30 */1 * * *   ~/Pascal/Code/Pascal/vbox-snapshots/vbox-snapshot.sh --running
40 */4 * * *   ~/Pascal/Code/Pascal/vbox-snapshots/vbox-snapshot-delete.sh --running --keep 4
10 16  * * *   ~/Pascal/Code/Pascal/vbox-snapshots/vbox-snapshot.sh --poweroff
20 */4  * * *   ~/Pascal/Code/Pascal/vbox-snapshots/vbox-snapshot-delete.sh --poweroff --keep 8
```
Takes a snapshot of running VMs every hour, and daily snapshots of halted ones.

### Important notes
- VMs that are neither in 'poweroff' nor 'running' state are ignored by both vbox-snapshot-delete.sh and vbox-snapshot.sh
- vbox-snapshot.sh --poweroff will only take snapshot of VMs that have not changed since last snapshot it took. That means running it daily does not necessarily means a snapshot a day if the VM has not been powered up between two passes.
- vbox-snapshot-delete.sh will only delete snapshots created by vbox-snapshot.sh, ie. ignore manully created ones or snapshots created by other scripts
- vbox-snapshot-delete.sh can only delete snapshots on VMs that are currently not running. Leaving a VMs running for days could thus lead to a huge amount of snapshots when taking snapshots with the --running option.

###### In short: keep an eye on your disk space
