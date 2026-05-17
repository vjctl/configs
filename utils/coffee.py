#!/usr/bin/env python3
"""
coffee.py - Keep your system awake by periodically moving the cursor

Automatically detects Windows/macOS/Linux and uses the appropriate method

Notes (Windows)
---------------
Windows has separate timers for (a) sleep / display power-off and (b) locking the
workstation (showing the sign-in screen). `SetThreadExecutionState()` reliably
helps with (a), but it does not always prevent (b) if Windows settings/policies
enforce it

If your PC still locks while Coffee is running, check:
- Screen saver settings: disable screen saver or uncheck "On resume, display logon screen"
- Settings → Accounts → Sign-in options: "Require sign-in" (if available)
- "Interactive logon: Machine inactivity limit" policy (`InactivityTimeoutSecs`)

As an optional workaround, run with `--prevent-lock` to also send a harmless
keyboard keepalive event (F15) each interval, which often resets the lock timer

Usage
-----
$ python coffee.py            # move every 60 s
$ python coffee.py -i 300     # move every 5 m
$ python coffee.py -i 30 -d   # run as a daemon in the background (macOS only)
$ python coffee.py --prevent-lock  # Windows: also try to prevent lock screen
"""

import argparse
import contextlib
import platform
import signal
import sys
import time

# Detect OS
IS_WINDOWS = platform.system() == "Windows"
IS_MAC = platform.system() == "Darwin"
IS_LINUX = platform.system() == "Linux"

# Global debug flag (set in main())
DEBUG = False

def log(*args, **kwargs):
    """Print only when --debug / -v supplied."""
    if DEBUG:
        print(*args, **kwargs)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Keep system awake by periodically moving the mouse cursor.")
    p.add_argument(
        "-i", "--interval",
        type=float,
        default=60.0,
        help="Seconds between cursor moves (default: 60)."
    )
    p.add_argument(
        "-d", "--daemon",
        action="store_true",
        help="Fork into the background after the first move (macOS/Linux only)."
    )
    p.add_argument(
        "-p","--prevent-lock",
        action="store_true",
        help="Windows only: also send a harmless keyboard keepalive event to reduce lock-screen timeouts."
    )
    p.add_argument(
        "-v", "--debug",
        action="store_true",
        help="Enable verbose debug output."
    )
    return p.parse_args()


@contextlib.contextmanager
def daemonize(enabled: bool):
    """
    If *enabled* is True, fork and let the parent exit so the child continues
    in the background (simple 'double-fork' daemon). Only works on Unix systems.
    """
    if not enabled:
        yield
        return

    if IS_WINDOWS:
        log("Warning: Daemon mode is not supported on Windows. Running in foreground.")
        yield
        return

    import os

    # First fork
    pid = os.fork()
    if pid > 0:
        sys.exit(0)

    # Detach from terminal & create new session
    os.setsid()

    # Second fork so the daemon can't acquire a controlling TTY
    pid = os.fork()
    if pid > 0:
        sys.exit(0)

    # Redirect stdio to /dev/null
    with open("/dev/null", "rb", 0) as devnull_in, \
         open("/dev/null", "wb", 0) as devnull_out:
        os.dup2(devnull_in.fileno(), sys.stdin.fileno())
        os.dup2(devnull_out.fileno(), sys.stdout.fileno())
        os.dup2(devnull_out.fileno(), sys.stderr.fileno())

    yield


def wiggle_windows(prevent_lock: bool = False):
    """
    Windows: Use SendInput to simulate actual mouse movement.
    This injects real input events that Windows treats as user activity.
    Also calls SetThreadExecutionState as a backup.
    """
    import ctypes
    from ctypes import wintypes

    # --- SetThreadExecutionState (backup method) ---
    ES_CONTINUOUS = 0x80000000
    ES_SYSTEM_REQUIRED = 0x00000001
    ES_DISPLAY_REQUIRED = 0x00000002
    ctypes.windll.kernel32.SetThreadExecutionState(
        ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED
    )

    # --- SendInput for actual mouse movement ---
    MOUSEEVENTF_MOVE = 0x0001
    KEYEVENTF_KEYUP = 0x0002
    VK_F15 = 0x7E  # "harmless" key most apps don't bind; used only for keepalive

    ULONG_PTR = getattr(wintypes, "ULONG_PTR", ctypes.c_size_t)

    class MOUSEINPUT(ctypes.Structure):
        _fields_ = [
            ("dx", wintypes.LONG),
            ("dy", wintypes.LONG),
            ("mouseData", wintypes.DWORD),
            ("dwFlags", wintypes.DWORD),
            ("time", wintypes.DWORD),
            ("dwExtraInfo", ULONG_PTR),
        ]

    class KEYBDINPUT(ctypes.Structure):
        _fields_ = [
            ("wVk", wintypes.WORD),
            ("wScan", wintypes.WORD),
            ("dwFlags", wintypes.DWORD),
            ("time", wintypes.DWORD),
            ("dwExtraInfo", ULONG_PTR),
        ]

    INPUT_MOUSE = 0
    INPUT_KEYBOARD = 1

    class _INPUT_UNION(ctypes.Union):
        _fields_ = [
            ("mi", MOUSEINPUT),
            ("ki", KEYBDINPUT),
        ]

    class INPUT(ctypes.Structure):
        _anonymous_ = ("i",)
        _fields_ = [
            ("type", wintypes.DWORD),
            ("i", _INPUT_UNION),
        ]

    # Move mouse 1 pixel right, then 1 pixel left
    def send_mouse_move(dx, dy):
        inp = INPUT(
            type=INPUT_MOUSE,
            mi=MOUSEINPUT(
                dx=dx,
                dy=dy,
                mouseData=0,
                dwFlags=MOUSEEVENTF_MOVE,
                time=0,
                dwExtraInfo=0,
            ),
        )
        ctypes.windll.user32.SendInput(1, ctypes.byref(inp), ctypes.sizeof(inp))

    def send_key_keepalive(vk: int) -> None:
        """
        Send a key down/up pair via SendInput. Used only as an optional keepalive
        to reduce Windows lock-screen timeouts.
        """
        inputs = (INPUT * 2)()

        inputs[0].type = INPUT_KEYBOARD
        inputs[0].ki = KEYBDINPUT(wVk=vk, wScan=0, dwFlags=0, time=0, dwExtraInfo=0)

        inputs[1].type = INPUT_KEYBOARD
        inputs[1].ki = KEYBDINPUT(wVk=vk, wScan=0, dwFlags=KEYEVENTF_KEYUP, time=0, dwExtraInfo=0)

        ctypes.windll.user32.SendInput(2, inputs, ctypes.sizeof(INPUT))

    send_mouse_move(1, 0)   # Move right 1px
    send_mouse_move(-1, 0)  # Move back left 1px
    if prevent_lock:
        send_key_keepalive(VK_F15)


def wiggle_mac():
    """
    macOS/Linux: Move the cursor by 1 px using pyautogui.
    """
    import pyautogui

    try:
        pyautogui.move(1, 0, duration=0)
    except pyautogui.FailSafeException:
        # Mouse was in a corner (PyAutoGUI fail-safe) - ignore and continue
        pass


def wiggle(prevent_lock: bool = False):
    """
    Move the cursor using the appropriate method for the current OS.
    """
    if IS_WINDOWS:
        wiggle_windows(prevent_lock=prevent_lock)
    else:
        wiggle_mac()


def main() -> None:
    args = parse_args()
    global DEBUG
    DEBUG = args.debug
    stop = False

    def _handler(signum, frame):
        nonlocal stop
        stop = True

    # Handle ^C and SIGTERM nicely
    signal.signal(signal.SIGINT, _handler)
    signal.signal(signal.SIGTERM, _handler)

    # Print OS detection info
    os_name = "Windows" if IS_WINDOWS else ("macOS" if IS_MAC else "Linux")
    log(f"☕ Coffee running on {os_name} (interval: {args.interval}s)")
    log("Press Ctrl+C to stop")

    with daemonize(args.daemon):
        while not stop:
            wiggle(prevent_lock=bool(getattr(args, "prevent_lock", False)))
            # Use shorter sleep intervals to respond quickly to stop signals
            for _ in range(int(args.interval / 0.2)):
                if stop:
                    break
                time.sleep(0.2)

    log("\n☕ Coffee stopped")


if __name__ == "__main__":
    main()
