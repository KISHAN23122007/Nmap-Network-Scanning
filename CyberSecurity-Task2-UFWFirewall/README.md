# Task 2 · Basic Firewall Configuration with UFW

## Objective
Set up and configure a basic firewall on a Linux system using UFW
(Uncomplicated Firewall), applying rules to allow and deny specific
types of traffic.

## What is a Firewall?
A firewall is a network security tool that monitors and controls
incoming and outgoing traffic based on a defined set of rules. It
acts as a barrier between a trusted internal network (or a single
machine) and untrusted external networks, deciding which
connections are allowed through and which are blocked. Firewalls
are one of the most basic and important layers of defense in
network security — without one, any service listening on any port
is reachable by anyone who can route traffic to the machine.

## What is UFW?
UFW (Uncomplicated Firewall) is a simplified, user-friendly
front-end for `iptables`, the default Linux firewall management
tool. Instead of writing complex iptables rules directly, UFW lets
you manage firewall rules with simple commands like
`ufw allow <port>` or `ufw deny <port>`.

## Installation
```bash
sudo apt update
sudo apt install ufw
```
On this system, UFW was already installed (version 0.36.2-9build1).

## Enabling UFW
```bash
sudo ufw enable
```
Output confirmed: `Firewall is active and enabled on system startup`

## Rules Configured

| Rule | Command | Purpose |
|---|---|---|
| Allow SSH (port 22) | `sudo ufw allow ssh` | Keeps remote/administrative access open so the machine doesn't get locked out of SSH management. |
| Deny HTTP (port 80) | `sudo ufw deny http` | Blocks unencrypted web traffic — HTTP traffic is unencrypted and can expose data to interception, so it's blocked in favor of HTTPS. |
| Allow HTTPS (port 443) | `sudo ufw allow https` | Allows secure, encrypted web traffic while still blocking the insecure HTTP equivalent. |
| Deny from specific IP | `sudo ufw deny from 192.168.1.100` | Demonstrates IP-based blocking — useful for blocking a known malicious or untrusted host from reaching the machine at all, regardless of port. |

### Why these rules?
- **SSH allowed** — administrative access must remain available, otherwise the machine becomes unmanageable remotely.
- **HTTP denied / HTTPS allowed** — this pairing enforces secure-only web traffic, a common real-world best practice since plain HTTP exposes data in transit.
- **IP-based deny** — shows that UFW can filter by source address as well as by port/service, which is useful for blocking specific known-bad hosts.

## Verifying Active Rules
```bash
sudo ufw status verbose
```
Screenshot included in repo (`ufw_status_verbose.png`) showing:
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     DENY IN     Anywhere
443                        ALLOW IN    Anywhere
Anywhere                   DENY IN     192.168.1.100
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                DENY IN     Anywhere (v6)
443 (v6)                   ALLOW IN    Anywhere (v6)
```

## Testing That Denied Traffic Is Blocked

**Method 1 — Loopback test (localhost):**
```bash
sudo python3 -m http.server 80   # start a temporary web server on port 80
curl http://localhost            # test access
```
**Finding:** The request succeeded (HTTP 200) even though a DENY
rule exists for port 80. This is expected UFW behavior, not a
misconfiguration — **UFW does not filter loopback (127.0.0.1)
traffic**. Rules only apply to traffic arriving through the actual
network interface, not to traffic a machine sends to itself.

**Method 2 — Remote test (recommended, actual proof of blocking):**
```bash
curl http://<VM-IP-address>
```
run from a **separate device on the same network**. This request
should fail/hang/timeout, confirming the DENY rule is actively
blocking external access to port 80.

This distinction (loopback vs. external testing) is an important
practical lesson in how host-based firewalls work.

## Files in This Repo
- `README.md` — this file
- `ufw_configuration.sh` — script that applies all rules in sequence
- `ufw_installation.png` — screenshot of UFW installation (`sudo apt install ufw`)
- `ufw_enable.png` — screenshot of UFW being enabled (`sudo ufw enable`)
- `ufw_allow_ssh.png` — screenshot of the SSH allow rule being added
- `ufw_allow_https.png` — screenshot of the HTTPS allow rule being added
- `ufw_status_verbose.png` — screenshot of `sudo ufw status verbose` showing all active rules (SSH, HTTP, HTTPS, IP deny)
- `ufw_deny_test_curl.png` — testing: `curl http://localhost` output after starting a test server on port 80
- `ufw_deny_test_setup.png` — testing: full rule setup + server start, shown together

## Ethics Note
This firewall configuration was applied only to a personal/local
VM used for learning purposes.
