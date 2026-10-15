# Disk Health Commands

## `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT`

Shows information about storage devices and partitions.

* **NAME** – Device or partition name
* **SIZE** – Device or partition size
* **TYPE** – Device type (`disk`, `part`, etc.)
* **FSTYPE** – Filesystem type (e.g. `ext4`, `ntfs`, `vfat`, `xfs`)
* **MOUNTPOINT** – Where the filesystem is mounted

---

## `df -h`

Displays disk space usage in a human-readable format.

* Total size
* Used space
* Available space
* Usage percentage
* Mounted filesystem

---

## `df -i`

Displays inode usage for each mounted filesystem.

Useful when a disk still has free space but cannot store new files because all inodes are used.

---

## `findmnt -D`

Displays information about mounted filesystems and their disk usage.

Unlike `df -h`, `findmnt -D` focuses on mounted filesystems and their source devices, making it useful for checking how storage devices are mounted.

---

## `sudo smartctl -a /dev/<device>`

Displays SMART information and disk health.

Example:

```bash
sudo smartctl -a /dev/sda
```

Provides information such as:

* SMART overall health status
* Temperature
* Power-on hours
* Reallocated sectors
* Pending sectors
* Error logs
* Device model and serial number
