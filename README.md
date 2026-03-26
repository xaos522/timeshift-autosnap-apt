# timeshift-autosnap-apt
A sophisticated, high-performance apt hook which runs before any `apt update|install|remove` command using a `DPkg::Pre-Invoke` hook in APT. Works best in `BTRFS` mode - `RSYNC` is also supported, but might be slow - for automated BTRFS/rsync snapshots using Timeshift.

Designed for users who want a "bulletproof" backup strategy, this script doesn't just take a snapshot—it understands the context of your system changes and ensures your snapshots are "snapshot-worthy" before they are created.

## Original Features
*  This script is a fork of [timeshift-autosnap](https://github.com/wmutschl/timeshift-autosnap-apt).
*  Creates [Timeshift](https://github.com/linuxmint/timeshift) snapshots with a unique (customizable) comment.
*  Keeps only a certain number of snapshots created using this script.
*  Deletes old snapshots which are created using this script.
*  Makes a copy with RSYNC of `/boot` and `/boot/efi` to `/boot.backup` before the call to Timeshift for more flexible restore options.
*  Can be manually executed by running `sudo timeshift-autosnap-apt`.
*  Autosnaphots can be temporarily skipped by setting "SKIP_AUTOSNAP" environment variable (e.g. `sudo SKIP_AUTOSNAP= apt upgrade`)
*  Supports [grub-btrfs](https://github.com/Antynea/grub-btrfs) which automatically creates boot menu entries of all your btrfs snapshots into grub.

## 🚀 New Key Features

* `Intelligent Context Logging`: Automatically identifies if a snapshot was triggered by a manual apt install, a GUI update (Aptdaemon), or a system upgrade.

* `Safety Valve Retention`: A hybrid deletion policy that keeps a week of snapshots but guarantees a minimum number (e.g., 3) are always kept, regardless of age.

* `Hook-in-Hook Architecture`: Supports pre-snapshot and post-snapshot scripts for syncing DKMS modules, initramfs, or databases before the backup begins.

* `Crash Resilience`: Uses a global exit trap and Wayland-compatible desktop notifications to alert you if a backup fails or a command crashes.

* `Performance First`: Optimized for speed using native Bash regex and one-pass configuration parsing.

## 📂 Directory Structure
| Path | Purpose |
| :--- | :--- |
| /usr/bin/timeshift-autosnap-apt |	The main execution script. |
| /etc/timeshift-autosnap-apt.conf | Configuration file for retention and thresholds. |
| /etc/timeshift-autosnap-apt/pre-snapshot.d/ | Place scripts here to run before the snapshot. |
| /etc/timeshift-autosnap-apt/post-snapshot.d/ | Place scripts here to run after a successful snapshot. |

## 🛠️ Advanced Usage: Hooks

* The power of this script lies in its extensibility. For example, to solve the common "NVIDIA black screen after restore" issue, you can create a script in the pre-snapshot.d folder:
```bash

# /etc/timeshift-autosnap-apt/pre-snapshot.d/01-sync-kernel
#!/bin/bash
# Ensure DKMS and Initramfs are synced so the snapshot is bootable
dkms autoinstall
update-initramfs -u
```

## ⚙️ New Configuration Options

Edit /etc/timeshift-autosnap-apt.conf to customize behavior:

* `snapshotThreshold`: (Seconds) Don't take a new snapshot if the last one is younger than this.
Running the 'Software Update' app in ubuntu can trigger the script multiple times in quick succession. The snapshotThreshold prevents taking a new snapshot at every invocation.

* `retentionPeriod` : (Seconds) How long to keep automated snapshots (Default: 7 days).

* `minKeepSnapshots` : The "Safety Valve"—never delete more than this many snapshots.

## 🖥️ Commands

* Test Notifications:
```bash
sudo timeshift-autosnap-apt --test-notify-send
```

* Dry Run:
```bash
sudo timeshift-autosnap-apt --dry-run
```

* Debug Mode:
```bash
sudo timeshift-autosnap-apt --debug
```

## Error handling

* When errors are detected
1. a desktop notification provides details about what went wrong
2. error messages are logged to syslog
3. the script will return a non-zero exit code and the software update will abort. The script will not allow the software update to proceed without having been able to create a valid snapshot.

## Installation
#### Install dependencies
```bash
sudo apt install git make libnotify-bin
```
#### Install and configure Timeshift
```bash
sudo apt install timeshift
```
Open Timeshift and configure it either using btrfs or rsync. I recommend using btrfs as a filesystem for this. Why? Because of its speed compared to rsync. btrfs snapshots are created in a fraction of a second.

#### Main installation
Clone this repository and install the script and configuration file with make:
```bash
git clone https://github.com/xaos522/timeshift-autosnap-apt.git /home/$USER/timeshift-autosnap-apt
cd /home/$USER/timeshift-autosnap-apt
sudo make install
```
After this, make changes to the configuration file:
```bash
sudo nano /etc/timeshift-autosnap-apt.conf
```
For example, if you don't have a dedicated `/boot` partition, then you should set `snapshotBoot=false`. This will still make a copy of `/boot/efi`.

#### Optionally, install `grub-btrfs`
[grub-btrfs](https://github.com/Antynea/grub-btrfs) is a great package which will include all btrfs snapshots into the Grub menu. Clone and install it:
```bash
git clone https://github.com/Antynea/grub-btrfs.git /home/$USER/grub-btrfs
cd /home/$USER/grub-btrfs
sudo make install
```
#### Original Configuration Options
The configuration file is located in `/etc/timeshift-autosnap-apt.conf`. You can set the following options:

*  `snapshotBoot`: If set to **true** /boot folder will be cloned with rsync into /boot.backup before the call to Timeshift. Note that this will not include the /boot/efi folder. Default: **true**
*  `snapshotEFI`: If set to **true** /boot/efi folder will be cloned with rsync into /boot.backup/efi before the call to Timeshift. Default: **true**
*  `skipAutosnap`: If set to **true** script won't be executed. Default: **false**.
*  `deleteSnapshots`: If set to **false** old snapshots won't be deleted. Default: **true**
*  `updateGrub`: If set to **false** GRUB entries won't be generated. Only if grub-btrfs is installed. Default: **true**
*  `snapshotDescription` Defines **string** used to distinguish snapshots created using timeshift-autosnap-apt. Default: **empty string**. The snapshotDescription you specify here will be prefixed by a hardcoded {timeshift-autosnap-apt}. The rest of the description will be automatically generated depending on how the script was invoked. For an apt update the description will show which packages were installed/removed/updated. For a 'Software Update' in  Ubuntu we do not have package information, but the description will show that the script was invoked by the Software Install app.

## Test functionality
To test the functionality, simply run
```bash
sudo timeshift-autosnap-apt --debug --dry-run
```
This will not create a new snapshot, but produce a trace of what would happen if it were not a dry run.

To create a new snapshot with feedback, run
```bash
sudo timeshift-autosnap-apt --debug
```

## Check syslog if the script is not behaving as expected
```bash
grep timeshift-autosnap-apt syslog
```
### Uninstallation
```bash
cd /home/$USER/timeshift-autosnap-apt
sudo make uninstall
```

## Ideas and contributions

**All new ideas and contributors are much appreciated and welcome, just open an issue for that!**
