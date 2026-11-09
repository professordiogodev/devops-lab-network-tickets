#!/usr/bin/env bash
rc=0
if [ -f tickets.md ] && [ "$(wc -w < tickets.md)" -ge 120 ] && [ "$(grep -ciE '^#+ .*(shop|blog|reports|admin)' tickets.md)" -ge 4 ]; then echo "- ✅ tickets.md covers the four tickets"
else echo "- ❌ tickets.md must have a section for shop, blog, reports and admin, with real content"; rc=1; fi
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
