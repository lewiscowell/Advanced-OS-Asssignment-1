#!/bin/bash

LOG="submission_log.txt"
MAX_SIZE=$((5 * 1024 * 1024))

get_time() {
    date "+%Y-%m-%d %H:%M:%S"
}

log_event() {
    echo "$(get_time)|$1|$2|$3" >> "$LOG"
}

get_hash() {
    md5sum "$1" | awk '{print $1}'
}

submit_assignment() {
    read -p "Student ID: " student_id
    read -p "File Name: " path

    if [ ! -f "$path" ]; then
        echo "File not found."
        log_event "$student_id" "N/A" "FAILED - file not found"
        return
    fi

    name=$(basename "$path")
    ext="${name##*.}"

    if [[ "$ext" != "pdf" && "$ext" != "docx" ]]; then
        echo "Only pdf or docx allowed."
        log_event "$student_id" "$name" "FAILED - invalid file type"
        return
    fi

    size=$(stat -c%s "$path")

    if [ "$size" -gt "$MAX_SIZE" ]; then
        echo "File size exceeds 5MB."
        log_event "$student_id" "$name" "FAILED - file too large"
        return
    fi

    hash=$(get_hash "$path")

    if [ -f "$LOG" ]; then
        while IFS="|" read time sid fname status; do

            if [[ "$status" == *"SUCCESS"* ]]; then

                if [ "$fname" = "$name" ]; then
                    echo "File rejected. Duplicate filename previously submitted."
                    log_event "$student_id" "$name" "FAILED - duplicate filename"
                    return
                fi

                if [[ "$status" == *"$hash"* ]]; then
                    echo "File rejected. Duplicate file content previously submitted."
                    log_event "$student_id" "$name" "FAILED - duplicate content"
                    return
                fi

            fi

        done < "$LOG"
    fi

    log_event "$student_id" "$name" "SUCCESS - submitted | HASH:$hash"
    echo "Assignment successfully submitted."
}

check_file() {
    read -p "Filename: " target
    found=0

    if [ -f "$LOG" ]; then
        while IFS="|" read time sid fname status; do
            if [[ "$fname" == "$target" && "$status" == *"SUCCESS"* ]]; then
                found=1
            fi
        done < "$LOG"
    fi

    if [ "$found" -eq 1 ]; then
        echo "Matching file has been found. Assignment has been previously submitted."
    else
        echo "No matching file has been found. Assignment has not been previously submitted."
    fi
}

list_submissions() {
    if [ ! -f "$LOG" ]; then
        echo "No assignments have been submitted."
        return
    fi

    while IFS="|" read time sid fname status; do
        if [[ "$status" == *"SUCCESS"* ]]; then
            echo "$sid -> $fname"
        fi
    done < "$LOG"
}

declare -A attempts
declare -A locked

login() {
    read -p "Student ID: " student_id
    read -p "Password: " pwd

    if [[ "${locked[$student_id]}" == "1" ]]; then
        echo "Account locked."
        log_event "$student_id" "LOGIN" "FAILED - account locked"
        return
    fi

    if [ "$pwd" = "password" ]; then
        echo "Login successful."
        attempts[$student_id]=0
        log_event "$student_id" "LOGIN" "SUCCESS"
    else
        attempts[$student_id]=$(( ${attempts[$student_id]:-0} + 1 ))
        echo "Incorrect password (${attempts[$student_id]}/3)"
        log_event "$student_id" "LOGIN" "FAILED - wrong password"

        if [ "${attempts[$student_id]}" -ge 3 ]; then
            locked[$student_id]=1
            echo "Account locked. Too many failed login attempts"
            log_event "$student_id" "LOGIN" "FAILED - account locked"
        fi
    fi
}

leave() {
read -p "Exit? (y/n): " confirm

if [ "$confirm" = "y" ]; then
    echo "Goodbye!"
    exit
fi
}

touch "$LOG"

while true; do
    echo ""
    echo "===== Student System ====="
    echo "1. Submit Assignment"
    echo "2. Check Submission"
    echo "3. List Submissions"
    echo "4. Login"
    echo "5. Exit"
    echo "=========================="

    read -p "Choice: " choice

    case $choice in
        1) submit_assignment ;;
        2) check_file ;;
        3) list_submissions ;;
        4) login ;;
        5) leave ;;
        *) echo "Invalid option." ;;
    esac
done
