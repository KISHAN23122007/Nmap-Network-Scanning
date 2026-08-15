# Task 3 — SQL Injection on DVWA (Low Security)

## Objective
Demonstrate a classic SQL Injection vulnerability by exploiting the
login form of DVWA (Damn Vulnerable Web Application) on its Low
security setting, and document the attack with an explanation of how
it works and how to prevent it.

## 1. What is SQL Injection?

SQL Injection (SQLi) is a vulnerability that occurs when user-supplied
input is inserted directly into a SQL query without being properly
validated or escaped. If an application builds queries by concatenating
raw input into a SQL string, an attacker can craft input that changes
the *structure* of the query itself — not just the data being searched
for — letting them read, modify, or extract data they were never meant
to access.

## 2. Environment Setup

DVWA was installed locally on Ubuntu using a LAMP stack (Apache, MySQL,
PHP) — not XAMPP, since XAMPP is primarily a Windows/cross-platform
bundle and a native LAMP install is the standard approach on Linux.

```bash
sudo apt update
sudo apt install apache2 mysql-server php php-mysqli php-gd libapache2-mod-php -y
sudo git clone https://github.com/digininja/DVWA.git /var/www/html/dvwa
cd /var/www/html/dvwa/config
sudo cp config.inc.php.dist config.inc.php
```

A dedicated MySQL user and database were created for DVWA (using root
directly is not recommended, per DVWA's own setup guidance):

```sql
CREATE DATABASE dvwa;
CREATE USER 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;
```

```bash
sudo chmod -R 777 /var/www/html/dvwa/hackable/uploads /var/www/html/dvwa/config
sudo systemctl restart apache2 mysql
```

**Compatibility note:** DVWA's setup script failed on first run with a
MySQL syntax error (`ADD COLUMN IF NOT EXISTS` is not supported on
MySQL 8.4, the version installed here). This was resolved by manually
adding the missing column before re-running setup:

```sql
USE dvwa;
ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'user';
```

After that, `http://localhost/dvwa/setup.php` → **Create / Reset
Database** completed successfully, creating the schema and seeding the
default `users` table.

## 3. Setting Security Level to Low

Logged in with the default DVWA credentials (`admin` / `password`),
then navigated to **DVWA Security** and set the level to **Low**. At
this setting, DVWA performs no input sanitisation or escaping on the
SQL Injection module — user input is concatenated directly into the
SQL query, exactly as it would be in a real, poorly-written
application.

## 4. Baseline — Normal Query

Navigated to **SQL Injection** and submitted a normal, expected input:

```
User ID: 1
```

Result: exactly one record returned (the user with ID 1), confirming
the form behaves as intended under normal use.

## 5. Payload 1 — Authentication/Logic Bypass

```
1' OR '1'='1
```

**Why it works:** The application's underlying query is structured
roughly like:

```sql
SELECT first_name, last_name FROM users WHERE user_id = '$id';
```

Substituting the payload in for `$id` turns this into:

```sql
SELECT first_name, last_name FROM users WHERE user_id = '1' OR '1'='1';
```

Because `'1'='1'` is always true, the `WHERE` clause matches **every
row** in the table, not just the one with `user_id = 1`.

**Result:** The page returned all 5 users in the database instead of
one — admin, Gordon Brown, Hack Me, Pablo Picasso, and Bob Smith —
confirming the query logic was successfully hijacked.

📸 See `screenshots/payload1_or_1equals1.png`

## 6. Payload 2 — UNION-Based Data Extraction

```
1' UNION SELECT user, password FROM users#
```

**Why it works:** A `UNION SELECT` appends the results of a second,
attacker-controlled query onto the original one, as long as the number
of columns matches. Here, the `users` table just happens to also
return two columns, letting the injected query line up cleanly with
the original `first_name` / `surname` output fields. The `#` character
comments out the rest of the original query so it doesn't cause a
syntax error.

**Note on syntax:** The standard `--` comment syntax was tried first
and caused a MySQL syntax error, because MySQL requires a space
immediately after `--` for it to be treated as a comment — a space
that gets silently trimmed when submitted through a URL/form field.
Using `#` avoided this issue entirely, since MySQL doesn't require a
trailing space after it.

**Result:** The query successfully extracted every username and
password hash stored in the database:

| Username | Password Hash |
|---|---|
| admin | `5f4dcc3b5aa765d61d8327deb882cf99` |
| gordonb | `e99a18c428cb38d5f260853678922e03` |
| 1337 | `8d3533d75ae2c3966d7e0d4fcc69216b` |
| pablo | `0d107d09f5bbe40cade3de5c71e9e9b7` |
| smithy | `5f4dcc3b5aa765d61d8327deb882cf99` |

📸 See `screenshots/payload2_union_select.png`

**Additional security observation:** These are 32-character hex
strings — MD5 hashes. MD5 is a cryptographically broken hashing
algorithm; it's fast to compute, has no built-in salting, and rainbow
tables for common passwords are widely available. In fact, `admin` and
`smithy` share the identical hash above, meaning they use the same
underlying password — this kind of pattern is trivial to spot once
hashes are exposed, and MD5 hashes for common passwords can typically
be reversed in seconds using free online lookup tools. This compounds
the severity of the SQL injection: not only was the data exposed, but
the exposed data is weakly protected in the first place.

## 7. How a Developer Would Fix This

The root cause is that user input is concatenated directly into a SQL
string instead of being treated strictly as data. The fix is to use
**parameterised queries (prepared statements)**, which separate the
SQL command structure from the values it operates on — the database
driver sends the query and the parameters separately, so user input
can never be interpreted as part of the query's logic no matter what
characters it contains.

Example fix in PHP (using `mysqli` prepared statements):

```php
// Vulnerable (current DVWA Low code):
$query = "SELECT first_name, last_name FROM users WHERE user_id = '$id'";
$result = mysqli_query($conn, $query);

// Fixed:
$stmt = $conn->prepare("SELECT first_name, last_name FROM users WHERE user_id = ?");
$stmt->bind_param("s", $id);
$stmt->execute();
$result = $stmt->get_result();
```

Additional hardening beyond parameterised queries:
- Enforce least-privilege database accounts (the app's DB user
  shouldn't have permissions beyond what it needs)
- Hash passwords with a modern, salted algorithm (bcrypt/Argon2), not
  MD5
- Apply input validation as a secondary defence layer (e.g. numeric-only
  validation for a field expected to be numeric)

## Files in This Repo

- `README.md` — this file
- `sql_injection_notes.md` — payload log and analysis
- `screenshots/` — baseline query, and both injection payload results
- `Demo Video.webm` — screen-recorded walkthrough of the exploit

## Ethics Note

This SQL injection was performed only against DVWA running locally on
my own machine, for learning purposes. SQL injection was never
attempted against any real, third-party, or production website or
service.
