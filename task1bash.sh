#!/bin/bash

LOG="system_monitor_log.txt"
ARCHIVE="ArchiveLogs"

log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG"
}

while true; do
	echo ""
	echo ""
	echo "----- System Administration Tool -----"
	echo "1. CPU and Memory Usage"
	echo "2. 10 Most Consuming Processes"
	echo "3. Terminate Process"
	echo "4. Disk & Logs"
	echo "5. Exit"
	echo "--------------------------------------"
	read -p "Option: " opt

case $opt in
	1)
	echo "------System Usage------"
	echo ""
	echo "CPU Information:"
        top -bn1 | grep "^%Cpu"

	echo "Memory Information:"
        free -m
        log "Viewed System Usage"
	echo ""
	echo "------------------------"
        ;;

        2)
        ps aux --sort=-%mem | head -11 | cut -c -120
        log "Viewed 10 Most Consuming Processes"
        ;;

	3)
        read -p "Select PID you want to terminate: " pid

        if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        echo "Please enter a valid PID number"
        continue
        fi

        if [ "$pid" -le 10 ]; then 
        echo "Cannot terminate critical system processes"
        log "Tried to terminate critical PID $pid"

        else
        read -p "Confirm (Y/N): " c
        [[ "$c" == [Yy] ]] && kill "$pid" && log "Terminated $pid"
        fi
        ;;

        4)
        read -p "Directory: " dir
        if [ -d "$dir" ]; then
        du -sh "$dir"
        mkdir -p "$ARCHIVE"
        for f in $(find "$dir" -name "*.log" -size +50M); do
	gzip -c "$f" > "$ARCHIVE/$(basename "$f")_$(date +%s).gz"
        log "Archived $f"
        done
        [ $(du -sm "$ARCHIVE" | cut -f1) -gt 1024 ] && echo "WARNING: ArchiveLogs >1GB" && log "Archive too big"

        else
        echo "Invalid directory"
        fi
        ;;

        5)
        read -p "Exit? (Y/N): " c
        [[ "$c" == [Yy] ]] && echo "Goodbye!" && exit 0	
	;;
esac
done
