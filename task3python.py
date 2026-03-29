#!/usr/bin/env python3

import os
import time
import hashlib
from datetime import datetime

SUBMISSION_LOG = "submission_log.txt"
LOGIN_LOG = "login_attempts.log"
MAX_SIZE = 5 * 1024 * 1024

failed_attempts = {}
last_login_time = {}
locked_accounts = set()


def get_time():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def get_hash(file_path):
    with open(file_path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def log_event(student_id, filename, status):
    with open(SUBMISSION_LOG, "a") as f:
        f.write(f"{get_time()}|{student_id}|{filename}|{status}\n")


def submit_assignment():
    student_id = input("Student ID: ")
    path = input("File Name: ")

    if not os.path.isfile(path):
        print("File not found.")
        log_event(student_id, "N/A", "FAILED - file not found")
        return

    name = os.path.basename(path)
    ext = name.split(".")[-1].lower()

    if ext not in ["pdf", "docx"]:
        print("Only pdf or docx allowed.")
        log_event(student_id, name, "FAILED - invalid file type")
        return

    size = os.path.getsize(path)
    if size > MAX_SIZE:
        print("File size exceeds 5MB")
        log_event(student_id, name, "FAILED - file size exceeds 5MB")
        return

    file_hash = get_hash(path)

    if os.path.exists(SUBMISSION_LOG):
        with open(SUBMISSION_LOG, "r") as f:
            for line in f:
                parts = line.strip().split("|")

                if len(parts) >= 4:
                    existing_name = parts[2]
                    existing_status = parts[3]

                    if "SUCCESS" in existing_status:

                        if existing_name == name:
                            print("File rejected. Duplicate filename previously submitted.")
                            log_event(student_id, name, "FAILED - duplicate filename")
                            return

                        if "HASH:" in existing_status:
                            existing_hash = existing_status.split("HASH:")[-1]

                            if existing_hash == file_hash:
                                print("File rejected. Duplicate file content previously submitted.")
                                log_event(student_id, name, "FAILED - duplicate content")
                                return

    log_event(student_id, name, f"SUCCESS - submitted | HASH:{file_hash}")
    print("Assignment successfully submitted.")


def check_file():
    target = input("File Name: ")
    found = False

    if os.path.exists(SUBMISSION_LOG):
        with open(SUBMISSION_LOG, "r") as f:
            for line in f:
                parts = line.strip().split("|")
                if len(parts) >= 3 and parts[2] == target:
                    found = True

    if found:
        print("Matching file has been found. Assignment has been previously submitted.")
    else:
        print("No matching file has been found. Assignment has not been previously submitted.")


def list_submissions():
    if not os.path.exists(SUBMISSION_LOG) or os.path.getsize(SUBMISSION_LOG) == 0:
        print("No assignments have been submitted.")
        return

    with open(SUBMISSION_LOG, "r") as f:
        for line in f:
            parts = line.strip().split("|")
            if len(parts) >= 3:
                print(parts[2])


def login():
    student_id = input("Student ID: ")
    pwd = input("Password: ")

    now = int(time.time())

    if student_id in locked_accounts:
        print("Account locked.")
        log_event(student_id, "LOGIN", "FAILED - account locked")
        return

    if student_id in last_login_time:
        if now - last_login_time[student_id] <= 60:
            print("WARNING: Too many attempts.")

    last_login_time[student_id] = now

    if pwd == "password":
        print("Login success.")
        failed_attempts[student_id] = 0
        log_event(student_id, "LOGIN", "SUCCESS")
    else:
        failed_attempts[student_id] = failed_attempts.get(student_id, 0) + 1
        print("Incorrect password.")
        log_event(student_id, "LOGIN", "FAILED - wrong password")
        print(f"Attempts: ({failed_attempts[student_id]}/3).")

        if failed_attempts[student_id] >= 3:
            locked_accounts.add(student_id)
            print("Account locked. Too many failed login attempts.")
            log_event(student_id, "LOGIN", "FAILED - account locked")


def main():
    open(SUBMISSION_LOG, "a").close()
    open(LOGIN_LOG, "a").close()

    while True:
        print("\n===== Student Submissions =====")
        print("1. Submit Assignment")
        print("2. Check Submissions")
        print("3. List Submissions")
        print("4. Login")
        print("5. Exit")
        print("===============================")
        option = input("Option: ")

        if option == "1":
            submit_assignment()
        elif option == "2":
            check_file()
        elif option == "3":
            list_submissions()
        elif option == "4":
            login()
        elif option == "5":
            confirm = input("Exit? (y/n): ").strip().lower()
            if confirm == "y":
                print("Goodbye!")
                break
        else:
            print("Invalid option.")


main()
