#!/usr/bin/env python3
"""
awake.py - Periodically move the cursor by 1 px to keep the system awake

Usage
-----
$ python awake.py            # move every 60 s
$ python awake.py -i 300     # move every 5 m
$ python awake.py -i 30 -d   # run as a daemon in the background
"""

import argparse
import atexit
import os
import signal
import subprocess
import sys
import time

import pyautogui

PID_FILE = "/tmp/awake.pid"


def _is_already_running() -> bool:
    """Check if another instance is already running via PID file"""
    if not os.path.exists(PID_FILE):
        return False
    try:
        with open(PID_FILE) as f:
            pid = int(f.read().strip())
        # Check if process is alive
        os.kill(pid, 0)
        return True
    except (ValueError, ProcessLookupError, PermissionError):
        # Invalid PID, process dead, or permission issue - safe to start
        return False


def _write_pid_file() -> None:
    """Write current PID to file and register cleanup"""
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))
    atexit.register(_cleanup_pid_file)


def _cleanup_pid_file() -> None:
    """Remove PID file on exit"""
    try:
        os.remove(PID_FILE)
    except OSError:
        pass


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Periodically move the mouse cursor")
    p.add_argument(
        "-i", "--interval",
        type=float,
        default=60.0,
        help="Seconds between cursor moves (default: 60)"
    )
    p.add_argument(
        "-d", "--daemon",
        action="store_true",
        help="Run in the background"
    )
    return p.parse_args()


def _spawn_detached_background_process() -> None:
    """Re-exec this script detached"""
    if os.environ.get("AWAKE_DAEMON") == "1":
        return

    # Relaunch with the same args but without -d/--daemon to avoid recursion
    child_argv = [sys.executable, os.path.abspath(__file__)]
    for arg in sys.argv[1:]:
        if arg in ("-d", "--daemon"):
            continue
        child_argv.append(arg)

    env = dict(os.environ)
    env["AWAKE_DAEMON"] = "1"

    with open("/dev/null", "rb", 0) as devnull_in, open("/dev/null", "wb", 0) as devnull_out:
        p = subprocess.Popen(
            child_argv,
            stdin=devnull_in,
            stdout=devnull_out,
            stderr=devnull_out,
            close_fds=True,
            start_new_session=True,
            env=env,
        )

    print(f"Started background process (pid={p.pid})")
    raise SystemExit(0)


def wiggle():
    """
    Move the cursor by (1, 0) pixels and then restore it
    """
    try:
        x, y = pyautogui.position()
        pyautogui.move(1, 0, duration=0)     # nudge
        # pyautogui.move(-1, 0, duration=0)  # restore
    except pyautogui.FailSafeException as e:
        # Mouse was in a corner (PyAutoGUI fail-safe) - ignore and continue
        # print(e)
        pass


def main() -> None:
    args = parse_args()

    # Prevent duplicate instances (check before spawning daemon so message is visible)
    if _is_already_running():
        print("awake.py is already running. Exiting!")
        sys.exit(0)

    if args.daemon:
        _spawn_detached_background_process()

    _write_pid_file()

    stop = False

    def _handler(signum, frame):
        nonlocal stop
        stop = True

    # Handle ^C and SIGTERM nicely
    signal.signal(signal.SIGINT, _handler)
    signal.signal(signal.SIGTERM, _handler)

    while not stop:
        wiggle()
        for _ in range(int(args.interval / 0.2)):
            if stop:
                break
            time.sleep(0.2)


if __name__ == "__main__":
    main()
