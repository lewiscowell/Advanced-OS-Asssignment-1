#!/bin/bash

Queue="job_queue.txt"
Completed="completed_jobs.txt"
Log="scheduler_log.txt"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$Log"; }

while true; do
    echo ""
    echo "===== Job Scheduler ====="
    echo "1. View Pending Jobs"
    echo "2. Submit A Job Request"
    echo "3. Process Job Queue"
    echo "4. View Completed Jobs"
    echo "5. Exit"
    echo ""

    read -p "Option: " opt

    case $opt in
    1)
        if [ ! -s "$Queue" ]; then
            echo "No Jobs Pending"
        else
            echo "Student ID | Job Name | Time | Priority"
            cat "$Queue"
        fi
        ;;

    2)
        read -p "Enter Student ID: " studentid
        read -p "Enter Job Name: " jobname
        read -p "Enter Estimated Time (seconds): " esttime
        read -p "Enter Priority (1-10): " priority

        if [[ "$priority" =~ ^([1-9]|10)$ ]]; then
            echo "$studentid|$jobname|$esttime|$priority" >> "$Queue"
            log "Job submitted: $studentid $jobname Priority:$priority Est:$esttime"
            echo "Job submitted."
        else
            echo "Invalid Number"
        fi
        ;;

    3)
        if [ ! -s "$Queue" ]; then
            echo "No jobs to process."
        else
            echo "1. Round Robin"
            echo "2. Priority"
            read -p "Option: " sch

            if [ "$sch" = "1" ]; then
                echo "Processing USing Round Robin..."

                quantum=5
                queue=()

                while read entry; do
                    queue+=("$entry")
                done < "$Queue"

                while [ ${#queue[@]} -gt 0 ]; do
                    new_queue=()

                    for entry in "${queue[@]}"; do
                        IFS='|' read studentid jobname esttime priority remaining <<< "$entry"
                        remaining=${remaining:-$esttime}

                        echo "Running: $jobname (Remaining: $remaining)"

                        if [ "$remaining" -le "$quantum" ]; then
                            sleep "$remaining"
                            remaining=0
                        else
                            sleep "$quantum"
                            remaining=$((remaining - quantum))
                        fi

                        if [ "$remaining" -gt 0 ]; then
                            new_queue+=("$studentid|$jobname|$esttime|$priority|$remaining")
                        else
                            echo "$studentid|$jobname|$esttime|$priority" >> "$Completed"
                            echo "Completed: $jobname"
                        fi
                    done

                    queue=("${new_queue[@]}")
                done

                > "$Queue"

            elif [ "$sch" = "2" ]; then
                echo "Processing Using Priority Scheduling..."

                sort -t'|' -k4 -nr "$Queue" | while read entry; do
                    IFS='|' read studentid jobname esttime priority <<< "$entry"

                    echo "Running: $jobname"
                    sleep "$esttime"

                    echo "$studentid|$jobname|$esttime|$priority" >> "$Completed"
                    echo "Completed: $jobname"
                done

                > "$Queue"

            else
                echo "Invalid"
            fi
        fi
        ;;

    4)
        if [ ! -s "$Completed" ]; then
            echo "No Jobs Completed."
        else
            echo "Completed Jobs:"
            cat "$Completed"
        fi
        ;;

    5)
        read -p "Exit? (Y/N): " c
        if [[ "$c" == [Yy] ]]; then
            echo "Goodbye!"
            exit 0
        fi
        ;;

    *)
        echo "Invalid option"
        ;;
    esac
done
