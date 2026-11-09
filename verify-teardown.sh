#!/usr/bin/env bash
# Proves the lab environment is gone. Run with: sudo ./verify-teardown.sh
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify-teardown.sh" >&2; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
no_user() { ! id "$1" >/dev/null 2>&1; }
no_group() { ! getent group "$1" >/dev/null 2>&1; }
no_path() { [ ! -e "$1" ]; }
no_proc() { ! pgrep -f "$1" >/dev/null 2>&1; }
no_listener() { ! ss -ltn 2>/dev/null | grep -qE ":$1\\b"; }

check "/etc/clippy-lab is gone" no_path /etc/clippy-lab
check "/tmp/clippy-lab is gone" no_path /tmp/clippy-lab
check "no clippy.test names left in /etc/hosts" bash -c "! grep -q clippy.test /etc/hosts"
check "no lab backend process is running" no_proc 'services/backend.py'
check "no lab gateway process is running" no_proc 'clippy-lab/gateway.py'
for p in 8080 9101 9102 9103 9104 9105; do check "port $p is free" no_listener $p; done

echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass)"; else echo "NOT CLEAN: $failn leftover(s). Finish the tear down steps and run this again."; fi
exit "$failn"
