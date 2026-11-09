#!/usr/bin/env python3
"""usage: backend.py NAME PORT BIND [DELAY_SECONDS]"""
import http.server, socketserver, sys, time
name, port, bind = sys.argv[1], int(sys.argv[2]), sys.argv[3]
delay = float(sys.argv[4]) if len(sys.argv) > 4 else 0
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        time.sleep(delay)
        body = f"{name}: hello from the {name} service\n".encode()
        self.send_response(200); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a): pass
class S(socketserver.ThreadingMixIn, http.server.HTTPServer): daemon_threads = True; allow_reuse_address = True
S((bind, port), H).serve_forever()
