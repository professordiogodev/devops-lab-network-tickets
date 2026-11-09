# Tickets
## shop.clippy.test
Symptom: curl says Could not resolve host. Evidence: getent hosts shop.clippy.test prints nothing, the other names resolve. Cause: no /etc/hosts entry. Fix: add it.
## blog.clippy.test
Symptom: 502 from the gateway, "connection refused" on 127.0.0.1:9112. Evidence: ss -ltnp shows blog listening on 9102 not 9112. Cause: wrong port in routes.conf. Fix: 9102.
## reports.clippy.test
Symptom: 504 after two seconds. Evidence: curl directly to 127.0.0.1:9103 takes four seconds, the gateway timeout is 2. Cause: timeout shorter than the backend. Fix: timeout = 6 (and a note to make the report faster).
## admin.clippy.test
Symptom: 502 connection refused to 127.0.0.2:9104. Evidence: ss -ltn shows 127.0.0.1:9104 only, nothing on 127.0.0.2. Cause: bound to localhost but the route uses another loopback address. Fix: point the route at 127.0.0.1.
