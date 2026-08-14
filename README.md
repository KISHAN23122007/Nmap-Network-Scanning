# Task 1 — Basic Network Scanning with Nmap

## 1. What is Nmap?

Nmap (Network Mapper) is a free, open-source tool used to discover hosts and
services on a computer network. It works by sending specially crafted packets
to a target and analyzing the responses. Nmap can tell you:

- Which hosts are up on a network
- Which ports on a host are open, closed, or filtered
- What service and version is running on each open port (e.g., OpenSSH 10.2p1)
- What operating system a host is likely running
- Whether a host has known vulnerabilities (via the Nmap Scripting Engine)

It's one of the most widely used tools in network administration and security
auditing, and is a standard part of the reconnaissance phase in penetration
testing.

## 2. Why network scanning matters

- **Visibility**: You can't secure what you don't know exists. Scanning shows
  you every open door into a system.
- **Attack surface reduction**: Every open port and running service is
  potential attack surface. Scanning helps identify services that should be
  disabled, firewalled, or updated.
- **Misconfiguration detection**: Scanning often reveals services running
  that nobody intended to expose.
- **Compliance & auditing**: Many security frameworks (PCI-DSS, ISO 27001)
  require regular scanning of assets.
- **Attacker's perspective**: Security teams scan their own systems the same
  way an attacker would, so they can find and fix issues first.

## 3. Ethical use guidelines ⚠️

- **Only scan machines you own or have explicit permission to scan.**
  Scanning systems without authorization can violate laws such as the U.S.
  Computer Fraud and Abuse Act, the UK Computer Misuse Act, or equivalent
  laws elsewhere — even if no damage is done.
- **This exercise was performed entirely against my own personal laptop**
  (hostname `kishan-PORTEGE-Z30t-B`), scanned over my own home Wi‑Fi network
  using its own local IP address. No external, third-party, or production
  system was scanned.
- **Scan traffic stayed on a private local network** (a home Wi‑Fi subnet),
  never touching the public internet or someone else's infrastructure.

> Note: The original task suggested scanning an isolated VM (e.g., Kali or
> Ubuntu in VirtualBox). For this run, my own laptop was scanned directly
> instead, which is still fully authorized since it's a machine I own — but
> it means the "target" and "attacker" are the same physical device, and the
> only genuinely open service found was SSH.

## 4. Lab setup used for this task

- Host / target OS: Ubuntu Linux (laptop: `kishan-PORTEGE-Z30t-B`, model Toshiba Portege Z30t-B)
- Target IP scanned: `10.95.171.90` (own machine's Wi‑Fi interface, `wlp2s0`)
- Network: home Wi‑Fi, `10.95.171.0/24`
- Nmap version: `7.98` (`https://nmap.org`)

## 5. Installing Nmap

Installed via the Ubuntu/Debian package manager.

```bash
sudo apt update
sudo apt install nmap
nmap --version
```

**Steps actually performed** (see `screenshots/` for terminal captures):

1. `sudo apt update` — refreshed package lists from `archive.ubuntu.com` and
   `security.ubuntu.com`.
2. `sudo apt install nmap` — installed `nmap 7.98+dfsg-1` along with
   dependencies `libblas3`, `liblinear4`, and `nmap-common` (~6.5 MB
   download, ~28.4 MB disk space used).
3. `nmap --version` — confirmed the install:

```
Nmap version 7.98 ( https://nmap.org )
Platform: x86_64-pc-linux-gnu
Compiled with: liblua-5.4.8 openssl-3.5.5 libssh2-1.11.1 libz-1.3.1
  libpcre2-10.46 libpcap-1.10.6 nmap-libdnet-1.18.0 ipv6
Available nsock engines: epoll poll select
```

## 6. Scans performed

### 6.1 Identifying the target IP
```bash
ip a
```
This showed the laptop's active Wi‑Fi interface `wlp2s0` with IP address
`10.95.171.90/24` (the loopback `lo` and the wired `enp0s25` interface were
down/unused). This IP was used as the scan target.

### 6.2 Basic scan
```bash
nmap 10.95.171.90
```
Default scan of the 1,000 most common TCP ports.

**Result:**
```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-07-30 11:12 +0530
Nmap scan report for kishan-PORTEGE-Z30t-B.local (10.95.171.90)
Host is up (0.00035s latency).
Not shown: 999 closed tcp ports (conn-refused)
PORT   STATE SERVICE
22/tcp open  ssh

Nmap done: 1 IP address (1 host up) scanned in 0.25 seconds
```

### 6.3 Service version scan
```bash
sudo nmap -sV 10.95.171.90
```

**Result:**
```
Starting Nmap 7.98 ( https://nmap.org ) at 2026-07-30 11:15 +0530
Nmap scan report for kishan-PORTEGE-Z30t-B.local (10.95.171.90)
Host is up (0.00014s latency).
Not shown: 999 filtered tcp ports (no-response)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 10.2p1 Ubuntu 2ubuntu3.5 (Ubuntu Linux; protocol 2.0)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at
https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 7.58 seconds
```

Note that running with `sudo` changed the scan type from a plain TCP
connect scan to a SYN scan, which is why "999 closed" (basic scan) became
"999 filtered" (sudo scan) — a raw-socket SYN probe behaves slightly
differently than a full TCP handshake when no service is listening.

### 6.4 OS detection scan — ✅ complete

```bash
sudo nmap -O 192.168.29.24
```

> **Note:** This scan was run in a later session, on a different Wi‑Fi
> network than the earlier scans (home router subnet `192.168.29.0/24`
> instead of `10.95.171.0/24`), so the target IP differs from sections 6.2
> and 6.3 above. Same physical laptop, same authorization basis (own
> machine, own network).

**Result:**

\`\`\`
Starting Nmap 7.98 ( https://nmap.org ) at 2026-08-14 17:58 +0530
Nmap scan report for kishan-PORTEGE-Z30t-B.local (192.168.29.24)
Host is up (0.00029s latency).
Not shown: 999 filtered tcp ports (no-response)
PORT   STATE SERVICE
22/tcp open  ssh
Warning: OSScan results may be unreliable because we could not find at least 1 open and 1 closed port
Aggressive OS guesses: Linux 5.0 - 6.2 (96%), Linux 5.8 (93%), HP P2000 G3 NAS device (92%), Linux 3.12 (91%), Linux 3.7 - 4.19 (91%), Linux 2.6.32 (91%), Linux 3.8 - 3.9 (91%), Linux 4.1 (91%), Linux 5.4 - 5.8 (91%), Linux 4.10 (91%)
No exact OS matches for host (test conditions non-ideal).
Network Distance: 0 hops

OS detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 12.48 seconds
\`\`\`

## 7. Findings summary

| Port | Service | Version                                   | Risk Level | Notes |
|------|---------|--------------------------------------------|------------|-------|
| 22   | ssh     | OpenSSH 10.2p1 (Ubuntu 2ubuntu3.5)          | Low–Medium | Only open port found; risk depends on auth config |

Only **one open port (22/tcp, SSH)** was found on this machine — everything
else was closed/filtered, which is a good sign for this laptop's exposure on
its home network. See `nmap_scan_results.txt` for the full port-by-port
security write-up.

## 8. Repository structure

```
.
├── README.md
├── nmap_scan_results.txt
└── screenshots/
    ├── nmap_installation.png
    ├── sudo_apt_update.png
    ├── nmap_version.png
    ├── ip_addr_and_basic_scan.png
    └── service_version_scan.png
```

## 9. References

- Official Nmap documentation: https://nmap.org/docs.html
- Nmap reference guide (man page): https://nmap.org/book/man.html
- Common ports and services (IANA registry):
  https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml
