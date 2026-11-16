
#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================
# FULL SSD CLONER
# Debian 13
# ==========================================

echo "===== FULL SSD CLONER ====="

# 1. ROOT CHECK
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run with sudo."
    exit 1
fi

# 2. DEPENDENCY CHECK
for cmd in whiptail lsblk jq dd blockdev findmnt swapon; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing dependency: $cmd"
        echo "Install: sudo apt install whiptail jq"
        exit 1
    fi
done

# 3. LIST PHYSICAL DISKS
mapfile -t DISKS < <(
    lsblk -J -d -o PATH,SIZE,MODEL,SERIAL,TYPE |
    jq -r '
        .blockdevices[]
        | select(.type == "disk")
        | [.path, .size, (.model // "Unknown"),
           (.serial // "Unknown")]
        | @tsv
    '
)

if (( ${#DISKS[@]} < 2 )); then
    echo "ERROR: Need at least two physical disks."
    exit 1
fi

# 4. SELECT SOURCE DISK
SOURCE_OPTIONS=()

for disk in "${DISKS[@]}"; do
    IFS=$'\t' read -r path size model serial <<< "$disk"

    SOURCE_OPTIONS+=(
        "$path"
        "$size | $model | SN: $serial"
    )
done

SRC=$(whiptail \
    --title "FULL SSD CLONER" \
    --menu "SELECT SOURCE SSD (DRIVE 1)" \
    22 90 12 \
    "${SOURCE_OPTIONS[@]}" \
    3>&1 1>&2 2>&3) || exit 0

# 5. SELECT DESTINATION DISK
DEST_OPTIONS=()

for disk in "${DISKS[@]}"; do
    IFS=$'\t' read -r path size model serial <<< "$disk"

    [[ "$path" == "$SRC" ]] && continue

    DEST_OPTIONS+=(
        "$path"
        "$size | $model | SN: $serial"
    )
done

DST=$(whiptail \
    --title "FULL SSD CLONER" \
    --menu "SELECT DESTINATION SSD (DRIVE 2)" \
    22 90 12 \
    "${DEST_OPTIONS[@]}" \
    3>&1 1>&2 2>&3) || exit 0

# 6. VALIDATE DEVICES
[[ "$SRC" != "$DST" ]] || exit 1
[[ -b "$SRC" && -b "$DST" ]] || {
    echo "ERROR: Invalid block device."
    exit 1
}

[[ "$(lsblk -dn -o TYPE "$SRC")" == "disk" ]] || exit 1
[[ "$(lsblk -dn -o TYPE "$DST")" == "disk" ]] || exit 1

SRC_SIZE=$(blockdev --getsize64 "$SRC")
DST_SIZE=$(blockdev --getsize64 "$DST")

if (( DST_SIZE < SRC_SIZE )); then
    echo "ERROR: Destination SSD is smaller."
    exit 1
fi

# 7. PREVENT CLONING A MOUNTED SOURCE
while read -r PART; do
    if findmnt -rn -S "$PART" >/dev/null; then
        echo "ERROR: Source contains a mounted filesystem."
        echo "Boot from a live USB and retry."
        exit 1
    fi
done < <(lsblk -nrpo NAME "$SRC")

# 8. PREVENT DESTINATION SWAP USAGE
while read -r SWAP; do
    while read -r PART; do
        if [[ "$(readlink -f "$SWAP")" == \
              "$(readlink -f "$PART")" ]]; then
            echo "ERROR: Destination contains active swap."
            exit 1
        fi
    done < <(lsblk -nrpo NAME "$DST")
done < <(swapon --show=NAME --noheadings --raw)

# 9. DISPLAY CLONE INFORMATION
clear

echo "======================================"
echo "SOURCE:      $SRC"
echo "SOURCE SIZE: $SRC_SIZE bytes"
echo "DESTINATION: $DST"
echo "DEST SIZE:   $DST_SIZE bytes"
echo "======================================"

echo
echo "WARNING: ALL DESTINATION DATA WILL BE DESTROYED."
echo

# 10. FIRST CONFIRMATION
if ! whiptail --title "WARNING" \
    --yesno "DESTINATION: $DST\n\nALL DATA ON THIS DISK WILL BE DESTROYED.\n\nContinue?" \
    15 70; then
    echo "Operation cancelled."
    exit 0
fi

# 11. SECOND CONFIRMATION
read -rp "Type CLONE to permanently confirm: " CONFIRM

if [[ "$CONFIRM" != "CLONE" ]]; then
    echo "Operation cancelled."
    exit 0
fi

# 12. UNMOUNT DESTINATION PARTITIONS
while read -r PART; do
    while read -r MOUNTPOINT; do
        [[ -z "$MOUNTPOINT" ]] && continue

        echo "Unmounting: $MOUNTPOINT"
        umount -- "$MOUNTPOINT" || {
            echo "ERROR: Cannot unmount $MOUNTPOINT"
            exit 1
        }
    done < <(findmnt -rn -S "$PART" -o TARGET)
done < <(lsblk -nrpo NAME "$DST")

# 13. FINAL DEVICE CHECK
[[ -b "$SRC" && -b "$DST" ]] || exit 1

echo
echo "===== STARTING FULL SSD CLONE ====="
echo "SOURCE: $SRC"
echo "DEST:   $DST"
echo

# 14. FULL DISK CLONE
dd if="$SRC" \
   of="$DST" \
   bs=64M \
   iflag=fullblock \
   status=progress \
   conv=fsync

# 15. SYNC
sync

# 16. VERIFY PARTITION LAYOUT
echo
echo "===== CLONE COMPLETED ====="
echo

lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS "$DST"

echo
echo "===== SSD CLONE FINISHED ====="
