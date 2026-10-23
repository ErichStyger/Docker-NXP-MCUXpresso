#!/bin/sh
# pkexec replacement for containers (no polkit, no dbus, no login session).
# The npm "sudo-prompt" library (used by the MCUXpresso Installer) looks for
# /usr/bin/pkexec and calls it as:
#   /usr/bin/pkexec --disable-internal-agent /bin/bash -c "<command>"
# The command is executed with passwordless sudo. Membership in the
# 'sudonopasswd' group (see Dockerfile) grants NOPASSWD sudo rights.

TARGET_USER=root

while [ $# -gt 0 ]; do
    case "$1" in
        --user|-u)
            TARGET_USER="$2"
            shift 2
            ;;
        --disable-internal-agent|--keep-cwd)
            shift
            ;;
        --version)
            echo "pkexec version 0.0 (sudo shim)"
            exit 0
            ;;
        --help|-h)
            echo "Usage: pkexec [--user username] PROGRAM [ARGUMENTS...]"
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

# No program given: start a shell, like the real pkexec does.
if [ $# -eq 0 ]; then
    set -- /bin/sh
fi

# -n: never prompt for a password. If passwordless sudo is not available,
# fail immediately with exit code 126, the same code the real pkexec uses
# for "not authorized", so callers like sudo-prompt report a clean failure
# instead of hanging forever waiting for a password that will never come.
if ! sudo -n true 2>/dev/null; then
    echo "pkexec shim: passwordless sudo not available for $(id -un)" >&2
    exit 126
fi

exec sudo -n \
    --preserve-env=DISPLAY,WAYLAND_DISPLAY,XDG_RUNTIME_DIR,XAUTHORITY,XDG_SESSION_TYPE \
    -u "$TARGET_USER" -- "$@"
