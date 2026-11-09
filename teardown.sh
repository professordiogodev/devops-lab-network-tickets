#!/usr/bin/env bash
# Removes the lab services and config. Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
[ -f /tmp/clippy-lab/pids ] && xargs -r kill < /tmp/clippy-lab/pids 2>/dev/null
pkill -KILL -f 'services/backend.py' 2>/dev/null; pkill -KILL -f '/tmp/clippy-lab/gateway.py' 2>/dev/null; sleep 1
sed -i '/# clippy-lab begin/,/# clippy-lab end/d' /etc/hosts
sed -i '/clippy\.test/d' /etc/hosts
rm -rf /etc/clippy-lab /tmp/clippy-lab
echo "Lab environment removed."
