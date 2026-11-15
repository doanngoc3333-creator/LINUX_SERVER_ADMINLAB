
#!/usr/bin/env bash
set -Eeuo pipefail

echo "===== FULL SSD CLONE ====="

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo."
    exit 1
fi

lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS

read -rp "SOURCE SSD (e.g. /dev/sda): " SRC
read -rp "DESTINATION SSD (e.g. /dev/sdb): " DST

# Validate device paths
[[ "$SRC" =~ ^/dev/(sd[a-z]|nvme[0-9]+n[0-9]+)$ ]] || exit 1
[[ "$DST" =~ ^/dev/(sd[a-z]|nvme[0-9]+n[0-9]+)$ ]] || exit 1
[[ "$SRC" != "$DST" ]] || exit 1

[[ -b "$SRC" && -b "$DST" ]] || {
    echo "Invalid block device."
    exit 1
}

SRC_SIZE=$(blockdev --getsize64 "$SRC")
DST_SIZE=$(blockdev --getsize64 "$DST")

if (( DST_SIZE < SRC_SIZE )); then
    echo "Destination SSD is smaller than source."
    exit 1
fi

echo "SOURCE: $SRC ($SRC_SIZE bytes)"
echo "DEST:   $DST ($DST_SIZE bytes)"

echo "WARNING: ALL DATA ON DESTINATION WILL BE DESTROYED."
read -rp "Type CLONE to confirm: " CONFIRM

[[ "$CONFIRM" == "CLONE" ]] || exit 1

# Unmount mounted partitions
while read -r PART; do
    [[ -n "$PART" ]] && umount "$PART"
done < <(lsblk -lnpo NAME,MOUNTPOINT "$DST" | awk '$2 != "" {print $1}')

# Clone entire disk, including partition tables and boot data
dd if="$SRC" of="$DST" bs=64M status=progress conv=fsync

sync

echo "===== CLONE COMPLETED ====="
echo "Verify destination partition layout:"
lsblk "$DST"
