#!/usr/bin/env bash
# Starts the gateway and five backends, and breaks four of them. Run with: sudo ./setup.sh (safe to re-run)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./setup.sh" >&2; exit 1; }
cd "$(dirname "$0")"
command -v python3 >/dev/null || { apt-get update -qq && apt-get install -y -qq python3 >/dev/null; }
./teardown.sh >/dev/null 2>&1 || true
mkdir -p /tmp/clipstr-lab /etc/clipstr-lab; : > /tmp/clipstr-lab/gateway.log
cp services/gateway.py /tmp/clipstr-lab/gateway.py; sha256sum services/gateway.py | cut -d' ' -f1 > /tmp/clipstr-lab/gateway.sha

# the routes the gateway uses (the ticket bugs are in here)
cat > /etc/clipstr-lab/routes.conf <<'C'
# host = which backend answers, and how long the gateway waits for it
[orders.clipstr.test]
upstream = 127.0.0.1:9101

[blog.clipstr.test]
upstream = 127.0.0.1:9112

[reports.clipstr.test]
upstream = 127.0.0.1:9103
timeout = 2

[admin.clipstr.test]
upstream = 127.0.0.2:9104

[shop.clipstr.test]
upstream = 127.0.0.1:9105
C

# names: four are registered, one (shop) is forgotten
cat >> /etc/hosts <<'H'
# clipstr-lab begin
127.0.0.1 orders.clipstr.test
127.0.0.1 blog.clipstr.test
127.0.0.1 reports.clipstr.test
127.0.0.1 admin.clipstr.test
# clipstr-lab end
H

run() { setsid nohup "$@" >/dev/null 2>&1 & echo $! >> /tmp/clipstr-lab/pids; }
: > /tmp/clipstr-lab/pids
run python3 services/backend.py orders  9101 0.0.0.0
run python3 services/backend.py blog    9102 0.0.0.0
run python3 services/backend.py reports 9103 0.0.0.0 4
run python3 services/backend.py admin   9104 127.0.0.1
run python3 services/backend.py shop    9105 0.0.0.0
run python3 /tmp/clipstr-lab/gateway.py
sleep 1.5
echo "Gateway listening on port 8080. Try:  curl http://orders.clipstr.test:8080"
curl -s --max-time 3 http://orders.clipstr.test:8080 || true
