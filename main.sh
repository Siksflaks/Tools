#!/bin/sh
# ====================================================
# =                                                  =
# =                Version: 1.0                      =
# =                                                  =
# ====================================================

# Voor update info zie LOG/main.log

VERSION="1.0"

# nu ook op Github

# path variables
default_backup_dir=""
manual_backup_dir=""
hourly_backup_dir=""
daily_backup_dir=""
weekly_backup_dir=""
monthly_backup_dir=""
log_file=""
 
clear

menu() {
    echo "========================="
    echo "  Maintenance Script"
    echo "  Version: $VERSION"
    echo "========================="
    echo "options:"
    echo "========================="
    echo "1. update"
    echo "2. backup"
    echo "3. info"
    echo "4. User options"
    echo "0. exit"
    echo "========================="
    read -p "Select an option: " option
    case $option in
        1)
            update
            ;;
        2)
            backup_menu
            ;;
        3)
            info
            ;;
        4)
            user_options
            ;;
        0)
            clear
            echo "Bye!"
            exit 0
            ;;
        patchnotes)
            clear
            cat "$log_file"
            read -p "Press enter to go back..." key
            clear
            menu
            ;;
        *)
            clear
            echo "Invalid option"
            menu
            ;;
    esac
}

update() {
    clear
    upgradable_packages=$(apt list --upgradable 2>/dev/null | grep -v "Listing...")
    apt update && apt upgrade -y
    clear
    echo "geupgrade pakketten:"
    echo "$upgradable_packages"
    menu
}

info() {
    clear
    page=1
    while true; do
        case $page in
            1)
                echo "Kernel version: $(uname -r)"
                echo "OS version: $(lsb_release -d | awk -F"\t" '{print $2}')"
                echo "Disk usage:"
                df -h
                ;;
            2)
                echo "Memory usage:"
                free -h
                echo "CPU info:"
                lscpu | grep "Model name"
                ;;
            3)
                echo "Network interfaces:"
                ip addr
                echo "Uptime:"
                uptime
                ;;
            4)
                echo "Last 10 logins:"
                last -n 10
                echo "Last 10 system logs:"
                tail -n 10 /var/log/syslog
                ;;
            *)
                echo "Invalid page"
                ;;
        esac
        echo "========================="
        read -p "Press N for next page, P for previous page, or M to return to menu: " key
        case $key in
            [Nn])
                page=$((page + 1))
                if [ $page -gt 4 ]; then
                    page=1
                fi
                ;;
            [Pp])
                page=$((page - 1))
                if [ $page -lt 1 ]; then
                    page=4
                fi
                ;;
            [Mm])
                clear
                menu
                break
                ;;
            *)
                echo "Invalid input"
                ;;
        esac
        clear
    done
}

user_options() {
    clear
    echo "========================="
    echo "  User Options"
    echo "========================="
    echo "1. Add user"
    echo "2. Delete user"
    echo "3. Change password"
    echo "4. Show users"
    echo "0. Go back"
    echo "========================="
    read -p "Select an option: " option
    case $option in
        1)
            add_user
            ;;
        2)
            delete_user
            ;;
        3)
            change_password
            ;;
        4)
            show_users
            ;;
        0)
            clear
            menu
            ;;
        *)
            echo "Invalid option"
            user_options
            ;;
    esac
}

add_user() {
    clear
    read -p "Enter username: " username
    read -p "Enter password: " password
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    echo "User $username added."
    read -p "Press enter to continue..." key
    user_options
}

delete_user() {
    clear
    read -p "Enter username to delete: " username
    userdel -r "$username"
    echo "User $username deleted."
    read -p "Press enter to continue..." key
    user_options
}

change_password() {
    clear
    read -p "Enter username to change password: " username
    read -p "Enter new password: " password
    echo "$username:$password" | chpasswd
    echo "Password for user $username changed."
    user_options
}

show_users() {
    clear
    echo "========================="
    echo "  User List"
    echo "========================="
    awk -F: '($3 >= 1000 && $3 < 65534) {print $1}' /etc/passwd | sort
    echo "========================="
    read -p "Press any key to go back..." key
    user_options
}

restore() {
    echo "========================="
    echo "  Paste the path to the backup file"
    echo "========================="
    read -p "Enter backup file path: " backup_file
    read -p "Enter location to restore to: " restore_location
    if [ ! -d "$restore_location" ]; then
        read -p "Directory $restore_location does not exist. Do you want to create it? (y/n): " create_dir
        if [ "$create_dir" = "y" ]; then
            mkdir -p "$restore_location"
            echo "Directory $restore_location created."
        else
            echo "Restore cancelled."
            backup_menu
            return
        fi
    fi
    read -p "Are you sure you want to restore the backup to $restore_location? (y/n): " confirm

    if [ "$confirm" != "y" ]; then
        echo "Restore cancelled."
        backup_menu
        return
    fi

    if [ -f "$backup_file" ]; then
        echo "Restoring backup..."
        if pv "$backup_file" | tar -xzf - -C "$restore_location"; then
            echo "Backup restored to $restore_location"
            echo "Restore complete..."
        else
            echo "Error: Failed to restore the backup."
        fi
    else
        echo "Backup file not found."
    fi

    read -p "Press any key to go back..." key
    backup_menu
}

show_backups() {
    clear
    echo "=========================" 
    echo "1. Manual backups"
    echo "2. Hourly backups"
    echo "3. Daily backups"
    echo "4. Weekly backups"
    echo "5. Monthly backups"
    echo "0. Go back"
    echo "========================="
    read -p "Select an option: " option

    case $option in
        1) backup_dir="$manual_backup_dir"; label="Manual backups";;
        2) backup_dir="$hourly_backup_dir"; label="Hourly backups";;
        3) backup_dir="$daily_backup_dir"; label="Daily backups";;
        4) backup_dir="$weekly_backup_dir"; label="Weekly backups";;
        5) backup_dir="$monthly_backup_dir"; label="Monthly backups";;
        0) clear; backup_menu; return;;
        *) echo "Invalid option"; show_backups; return;;
    esac

    while true; do
        clear
        echo "========================="
        echo "$label:"
        ls -1 "$backup_dir"/*.tar.gz 2>/dev/null || echo "No backups found."
        echo "========================="
        echo "Enter the full path of the backup to delete, or type 0 to go back."
        read -p "Backup path to delete: " del_path
        if [ "$del_path" = "0" ]; then
            show_backups
            return
        fi
        if [ -f "$del_path" ]; then
            read -p "Are you sure you want to delete $del_path? (y/n): " confirm
            if [ "$confirm" = "y" ]; then
                rm -f "$del_path"
                echo "Backup \"$del_path\" deleted."
            else
                echo "Delete cancelled."
            fi
        else
            echo "File not found or invalid path."
        fi
        sleep 1
    done
}


backup() {
    clear
    src_dir="${1:-$default_backup_dir}"
    dest_dir="${2:-$manual_backup_dir}"
    backup_name="${3:-backup_$(date +"%d-%m-%Y_%H-%M-%S")}"

    mkdir -p "$dest_dir"
    tar -cf - -C "$src_dir" . | pv -s $(du -sb "$src_dir" | awk '{print $1}') | gzip > "$dest_dir/$backup_name.tar.gz"
    echo "Backup complete: $dest_dir/$backup_name.tar.gz"
    read -p "Press enter to return to the backup menu..." key
    backup_menu
}

backup_menu () {
    clear
    echo "========================="
    echo "  Backup Options"
    echo "========================="
    echo "1. Make backup from default location ($default_backup_dir)"
    echo "2. Make backup from specified location"
    echo "3. Restore backup"
    echo "4. Show backups"
    echo "0. Go back"
    echo "========================="
    read -p "Select an option: " option
    case $option in
        1)
            backup "$default_backup_location" "$manual_backup_dir"
            ;;
        2)
            read -p "Enter the directory to backup: " src_dir
            if [ ! -d "$src_dir" ]; then
                echo "Directory does not exist."
                read -p "Press enter to go back..." key
                backup_menu
                return
            fi
            read -p "Enter backup name (leave empty for default): " backup_name
            if [ -z "$backup_name" ]; then
                backup_name="backup_$(date +"%d-%m-%Y_%H-%M-%S")"
            fi
            backup "$src_dir" "$manual_backup_dir" "$backup_name"
            ;;
        3)
            restore
            ;;
        4)
            show_backups
            ;;
        0)
            clear
            menu
            ;;
        *)
            echo "Invalid option"
            backup_menu
            ;;
    esac
}

menu