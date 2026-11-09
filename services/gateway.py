#!/usr/bin/env python3
"""A tiny reverse proxy. Reads /etc/clipstr-lab/routes.conf on every request, so config edits apply instantly."""
import configparser, http.server, socket, socketserver, sys, time, urllib.error, urllib.request

CONF = "/etc/clipstr-lab/routes.conf"
LOG = "/tmp/clipstr-lab/gateway.log"

def log(msg):
    with open(LOG, "a") as f:
        f.write(f"{time.strftime('%H:%M:%S')} {msg}\n")

class Handler(http.server.BaseHTTPRequestHandler):
    def reply(self, code, text):
        body = (text + "\n").encode()
        self.send_response(code); self.send_header("Content-Type", "text/plain"); self.send_header("Content-Length", str(len(body)))
        self.end_headers(); self.wfile.write(body)

    def do_GET(self):
        host = (self.headers.get("Host") or "").split(":")[0]
        cp = configparser.ConfigParser(); cp.read(CONF)
        if host not in cp:
            log(f"404 unknown host '{host}'"); return self.reply(404, f"gateway: no route for host '{host}'")
        upstream = cp[host]["upstream"]; timeout = float(cp[host].get("timeout", "2"))
        try:
            with urllib.request.urlopen(f"http://{upstream}/", timeout=timeout) as r:
                log(f"200 {host} -> {upstream}"); self.reply(200, r.read().decode().strip())
        except urllib.error.URLError as e:
            if isinstance(e.reason, socket.timeout) or "timed out" in str(e.reason):
                log(f"504 {host} -> {upstream} timed out after {timeout}s"); self.reply(504, f"gateway: upstream {upstream} did not answer within {timeout}s")
            else:
                log(f"502 {host} -> {upstream} {e.reason}"); self.reply(502, f"gateway: could not reach upstream {upstream} ({e.reason})")
        except socket.timeout:
            log(f"504 {host} -> {upstream} timed out after {timeout}s"); self.reply(504, f"gateway: upstream {upstream} did not answer within {timeout}s")

    def log_message(self, *a): pass

class Server(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True; allow_reuse_address = True

if __name__ == "__main__":
    Server(("0.0.0.0", 8080), Handler).serve_forever()
