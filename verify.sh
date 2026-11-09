#!/usr/bin/env bash
# Run with: sudo ./verify.sh
set -uo pipefail
cd "$(dirname "$0")"
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo:  sudo ./verify.sh" >&2; exit 1; }
[ -d /tmp/clipstr-lab ] || { echo "Run sudo ./setup.sh first"; exit 1; }
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
works() { local out; out=$(curl -s --max-time 10 "http://$1.clipstr.test:8080") && [[ "$out" == "$1:"* ]]; }

echo "== The tickets =="
check "orders still works (you did not break the control)"   works orders
check "Ticket: shop resolves and answers"                    works shop
check "Ticket: blog answers"                                 works blog
check "Ticket: reports answers (slow, but answers)"          works reports
check "Ticket: admin answers"                                works admin

echo "== Fair play =="
check "the gateway program itself was not modified"          bash -c "[ \"\$(sha256sum services/gateway.py | cut -d' ' -f1)\" = \"\$(cat /tmp/clipstr-lab/gateway.sha)\" ]"
check "admin is still bound to localhost only (no cheating by opening the backend to the world)" bash -c "ss -ltn | grep -q '127.0.0.1:9104'"
check "reports timeout is not absurd (under 30s)"            bash -c "t=\$(awk '/\\[reports/{f=1} f&&/timeout/{print \$3; exit}' /etc/clipstr-lab/routes.conf); awk -v t=\"\${t:-2}\" 'BEGIN{exit !(t<30)}'"

echo "== Your write-up =="
check "tickets.md has a section for all four tickets"        bash -c "[ \$(grep -ciE '^#+ .*(shop|blog|reports|admin)' tickets.md) -ge 4 ]"
check "tickets.md is more than a template (>= 120 words)"     bash -c "[ \$(wc -w < tickets.md) -ge 120 ]"

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$pass)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
