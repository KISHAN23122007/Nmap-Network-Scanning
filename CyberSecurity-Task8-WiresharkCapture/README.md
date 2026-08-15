# Task 8 — Capture Network Traffic with Wireshark

## Objective
Capture live network traffic using Wireshark, apply display filters to
isolate specific protocols, analyse packet contents, and document
findings with security observations.

## 1. What is Wireshark?

Wireshark is a free, open-source network protocol analyser. It captures
traffic passing through a network interface in real time and lets you
inspect every packet down to the individual byte — source and
destination addresses, protocols used, and (if unencrypted) the actual
data being sent.

It's the de facto standard tool for network troubleshooting, protocol
development, and security analysis. Where Nmap tells you *what's
listening* on a network, Wireshark shows you *what's actually being
said* between two hosts.

## 2. Installation

```bash
sudo apt update
sudo apt install wireshark -y
```

📸 See `screenshots/installation/wireshark_apt_update.png` and
`screenshots/installation/wireshark_apt_install.png`

During installation, a configuration prompt appears:

```
Should non-superusers be able to capture packets?
```

Selecting **Yes** here allows Wireshark to run under a normal user
account rather than requiring `sudo` every time — this is the
recommended setup because running the whole application as root
increases the amount of code running with elevated privileges.

📸 See `screenshots/installation/wireshark_capture_permission_prompt.png`

After installing, the user must be added to the `wireshark` system
group for the permission to take effect:

```bash
sudo usermod -aG wireshark $USER
```

**Note:** A full logout/login (or reboot) is required after this
command — group membership changes don't apply to an already-active
session.

📸 See `screenshots/installation/wireshark_usermod_group.png`

## 3. Capturing Traffic

Interface used: `wlp2s0` (WiFi)

A live capture was run for approximately 3.5 minutes
(17:05:54 – 17:09:41) while browsing several regular HTTPS sites and
deliberately visiting `http://neverssl.com` — a site intentionally
served over plain HTTP, used here to guarantee unencrypted traffic to
analyse (nearly all modern sites default to HTTPS, so plain HTTP
traffic isn't guaranteed otherwise).

Total packets captured: **55,142**

📸 See `screenshots/installation/wireshark_live_capture_dns.png` (capture
in progress) and `screenshots/installation/wireshark_neverssl_capture.png`
(NeverSSL open in the browser alongside the live capture, generating
the unencrypted traffic analysed below)

## 4. HTTP Traffic Filter

Filter applied: `http`

Result: 19 matching packets, including several requests to
`neverssl.com` (resolved IP `34.223.124.45`) —
`GET /`, `GET /online/`, `GET /favicon.ico`, and their corresponding
`200 OK` responses.

📸 See `screenshots/http_filter.png`

## 5. DNS Traffic Filter

Filter applied: `dns`

Result: 51,211 matching packets (92.9% of total capture) — mostly
standard query responses resolving domain names to IP addresses
(A/AAAA records) and CNAME redirects for services like
`accuweather.com`, `theguardian.com`, and `indiatoday.in`.

📸 See `screenshots/dns_filter.png`

## 6. TCP Three-Way Handshake

Filter applied: `tcp`

A complete handshake was identified for the connection to
`neverssl.com` (34.223.124.45) on port 80:

| Packet # | Source → Destination | Flags | Meaning |
|---|---|---|---|
| 34223 | 192.168.29.24 → 34.223.124.45 | `[SYN]` | Client requests to open a connection |
| 34381 | 34.223.124.45 → 192.168.29.24 | `[SYN, ACK]` | Server acknowledges and agrees to connect |
| 34382 | 192.168.29.24 → 34.223.124.45 | `[ACK]` | Client confirms — connection established |

Immediately after (packet 34383), the client sends its first real
data: `GET / HTTP/1.1`.

📸 See `screenshots/tcp_handshake.png`

## 7. Unencrypted Data — Security Finding

Packet **34383** (`GET / HTTP/1.1`, sent to neverssl.com) is plain-text
HTTP. Opening this packet in Wireshark and expanding the "Hypertext
Transfer Protocol" layer shows the full request in readable ASCII,
including:

- The exact path being requested (`/`)
- The `Host:` header, revealing the destination domain
- The `User-Agent` string, revealing browser/OS details

None of this is encrypted. Anyone able to observe traffic on the same
network — a shared WiFi hotspot, a compromised router, or an attacker
performing a man-in-the-middle — could read this data directly out of
the packet, exactly as Wireshark displays it here.

### Why unencrypted HTTP traffic is dangerous

HTTP sends all data — URLs, form submissions, cookies, session tokens,
sometimes even login credentials on poorly-built sites — as plain text.
Anyone in a position to intercept the traffic (same network, malicious
router, ISP, or a hostile actor running a packet sniffer like the one
used in this task) can read it without needing to break any encryption,
because there isn't any. This is what's known as **eavesdropping** or
**passive sniffing**.

### How HTTPS prevents this

HTTPS wraps HTTP inside TLS (Transport Layer Security). Before any data
is exchanged, the client and server perform a TLS handshake that
establishes a shared encryption key. From that point on, every byte
sent between them is encrypted — so even if an attacker captures the
same packets with a tool like Wireshark, all they see is scrambled
ciphertext (visible in this capture as `Application Data` packets under
the `TLSv1.2` protocol), not the actual content. HTTPS also verifies
the server's identity via a certificate, which protects against an
attacker impersonating the destination server.

## 8. Glossary

- **Packet** — A small chunk of data with a header attached, sent
  across a network. Large transfers (a web page, a file) are broken
  into many packets, sent independently, and reassembled at the
  destination.

- **Protocol** — An agreed-upon set of rules that both sides of a
  connection follow so they can understand each other — e.g. HTTP
  defines how a browser asks a server for a web page, and how the
  server replies.

- **Port** — A number attached to a connection that identifies which
  application or service on a device should receive the traffic. A
  single device can run many services at once (web server, SSH, email)
  and the port number is how incoming traffic gets routed to the right
  one — e.g. port 80 for HTTP, port 443 for HTTPS.

- **Payload** — The actual data being carried inside a packet, as
  opposed to the header information (addresses, port numbers, flags)
  wrapped around it. In an unencrypted HTTP packet, the payload is the
  literal request or response text.

- **Handshake** — A short exchange of setup messages both sides send
  before real data starts flowing, used to agree on connection
  parameters. TCP's handshake (SYN, SYN-ACK, ACK) confirms both sides
  are ready to communicate before anything else is sent.

## Files in This Repo

- `README.md` — this file
- `wireshark_capture.pcapng` — the full raw packet capture
- `screenshots/http_filter.png` — HTTP-filtered packet list
- `screenshots/dns_filter.png` — DNS-filtered packet list
- `screenshots/tcp_handshake.png` — TCP filter showing the SYN/SYN-ACK/ACK sequence
- `Demo Video.webm` — screen-recorded walkthrough of the capture and analysis

## Ethics Note

This capture was performed only on a personal home WiFi network that
I own and administer, for learning purposes. No traffic was captured
on any public, shared, or third-party network.
