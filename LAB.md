# LAB | Networking: Four Tickets Before Lunch

## The situation

Exam week at the university. The campus cafe sells coffee to two thousand students who have not slept, and every order and receipt goes through Clippy links. At 09:40 the support channel looks like this:

```text
#support                                                      Tue 09:40
dara (library desk)   shop link is dead. students are queueing for nothing
ben (cafe manager)    the blog page says "bad gateway". is that bad?
lucia (finance)       reports takes forever and then dies. I need it for 11:00
tomas (it helpdesk)   admin panel unreachable. devs say "works on my machine"
cto                   four people, four messages, one word: DOWN. who has this?
```

*You do.* "Down" means four different things here. One name does not resolve. One route points at the wrong port. One service is too slow for its proxy. One is listening where nobody can reach it. Each needs a different tool, and guessing will waste your morning.

> **Your mission**
> - Reproduce each ticket and read the exact error
> - Use the **right tool for each layer** (DNS, port, process, HTTP) to find the real cause
> - Fix the cause, not the symptom, and write it down like a professional

**Time:** 60-75 min | **Cost:** free | **You need:** your Ubuntu environment with `sudo` and Python 3. The lab starts a few small local services, `sudo ./teardown.sh` removes them.

---

## Part 0 - Open the queue

Fork this repository, clone your fork, and run:

```bash
sudo ./setup.sh
```

It starts a **gateway** (a small reverse proxy on port 8080) and five **backend services**. The gateway decides where to send a request using the `Host` header and the file `/etc/clippy-lab/routes.conf`. Read that file, it is the map of the whole system.

---

## Part 1 - Before the tickets: learn what "healthy" looks like

<!-- gif: recon -->

Start with the one that works:

```bash
curl -v http://orders.clippy.test:8080
```

1. Read the whole `-v` output. Find: the **resolved IP**, the **port**, the **request line**, the `Host` header and the **status code**.
2. Run `curl http://127.0.0.1:8080`. It connects but answers 404. Why? What changed compared with the call above?
3. List what is listening on this machine: `ss -ltnp`. Find the gateway (8080) and the five backends. Which addresses are they bound to? (`0.0.0.0` means all interfaces, `127.0.0.1` means this machine only.)
4. Read `cat /tmp/clippy-lab/gateway.log` after a few requests. This is where the gateway tells its story.

> **Think** A browser sends `Host: orders.clippy.test` and so does `curl`. What would happen if two websites shared one IP address and one port, and the server did not look at the Host header?

---

## Part 2 - The four tickets

Work each ticket the same way: **symptom, hypothesis, test, cause, fix**. Fill in `tickets.md` as you go. Write your hypothesis *before* the next command, even a wrong one.

### Ticket 1 - Dara: "shop link is dead"

```bash
curl -v http://shop.clippy.test:8080
```

> **Predict** Gateway, backend, or something earlier? Which of `getent hosts`, `dig`, `ping`, `ss` and `curl --resolve` will confirm it fastest?

Find the cause and fix it. (`getent hosts name` shows how this machine resolves names, including `/etc/hosts`.)

### Ticket 2 - Ben: "the blog says bad gateway"

The error says the gateway could not reach an upstream. Read the exact port. Then ask the machine what is actually listening, and compare. Find the cause and fix it.

### Ticket 3 - Lucia: "reports takes forever and then dies"

```bash
time curl -s -o /dev/null -w '%{http_code}\n' http://reports.clippy.test:8080
time curl -s http://127.0.0.1:9103
```

Compare the two timings. What does the difference tell you about who is at fault, the backend or the gateway? Fix it in a way you could defend in a post-mortem, and write down what the *better* long-term fix would be.

### Ticket 4 - Tomas: "admin unreachable, works on my machine"

It looks like ticket 2. It is not. Run `ss -ltn` and read the **local address** column of the admin backend carefully. Then read the route to admin in `routes.conf`.

> **Break it** Do **not** fix this one by making the backend listen on `0.0.0.0`: `verify.sh` penalises that. Explain in your ticket why binding an admin interface to the whole network is a bad habit, and fix the route instead.

---

## Part 3 - Prove it, then close the tickets

```bash
sudo ./verify.sh
```

Then make sure `tickets.md` is a document the next person on call could use: for each ticket the symptom, the command that found the cause with a one-line interpretation, the cause, and the fix. That is your reply to the channel.

---

## Level up (optional)

- **Trace the layers.** For `orders`, capture the traffic: `sudo tcpdump -i lo -nn port 9101 -A -c 10` while you curl it. Find the request the gateway makes on your behalf.
- **Bypass DNS.** `curl --resolve shop.clippy.test:8080:127.0.0.1 http://shop.clippy.test:8080` works before you fix the hosts file. Why? In which real situations is this trick useful?
- **Check the status codes.** Which of 404, 502 and 504 mean "the proxy is fine, something behind it is not"?

<!-- teardown:start (generated by labs.py, do not edit) -->
## Tear down (mandatory)

Resources left behind cost money, keep doors open and pollute the next lab. Removing what you created is part of the job, so it is part of the submission: **you must prove it is gone**.

Do this **last**, after you have pasted your `verify` output into `SUBMISSION.md` (once you tear down, the lab can no longer be verified).

1. Run `sudo ./teardown.sh`. It stops the gateway and the five backends and removes `/etc/clippy-lab`, the `/etc/hosts` entries and the logs.
2. If you added a `shop.clippy.test` line to `/etc/hosts` by hand, `teardown.sh` removes that too.

Then run the proof:

```bash
sudo ./verify-teardown.sh
```

It prints a list of checks and must end with **TEARDOWN VERIFIED**. If it reports leftovers, remove them and run it again. Paste the full output in your submission.
<!-- teardown:end -->

<!-- submission:start (generated by labs.py, do not edit) -->
## Submission

Answer the questions in `SUBMISSION.md` in **your fork** (paste output in code blocks where asked), push, then submit the **URL of your fork**.

**Files to commit**

- `tickets.md`: your diagnosis for each ticket (symptom, evidence, cause, fix), committed to the repo

**Questions to answer**

1. For each ticket, which tool gave you the answer, and which command? Why did the other tools you tried not help?
2. What is the difference between `Connection refused`, `Could not resolve host` and a timeout? Which layer of the stack does each point at?
3. Why did `curl http://127.0.0.1:8080` give a 404 while `curl http://orders.clippy.test:8080` worked? What is the Host header?
4. For the admin ticket, what did `ss -ltn` show, and what is the difference between binding to 127.0.0.1 and to 0.0.0.0? Why does it matter in production?
5. Paste the output of `sudo ./verify.sh`. It must end with **ALL CHECKS PASSED**.
6. **Tear down.** Paste the output of `sudo ./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.
<!-- submission:end -->
