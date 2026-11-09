#!/usr/bin/env bash
# Removes the lab services and config. Run with: sudo ./teardown.sh
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo" >&2; exit 1; }
[ -f /tmp/clipstr-lab/pids ] && xargs -r kill < /tmp/clipstr-lab/pids 2>/dev/null
pkill -f 'services/backend.py' 2>/dev/null; pkill -f '/tmp/clipstr-lab/gateway.py' 2>/dev/null
sed -i '/# clipstr-lab begin/,/# clipstr-lab end/d' /etc/hosts
sed -i '/clipstr\.test/d' /etc/hosts
rm -rf /etc/clipstr-lab /tmp/clipstr-lab
echo "Lab environment removed."
