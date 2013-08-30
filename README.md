YubiAuthd
=========

YubiAuthd provides a means of authenticating YubiKey OTP (one time password) challenges from local users across multiple systems. Once configured authentication is straightforward:

    $ yubiauth iivkctnggrticfbuvbbrrddlhvkduillucdffgvrelgv
    $ echo $?
    0

The user is identified by both the YubiKey public ID and the UNIX user ID attempting authentication. The yubiauth client connects to yubiauthd over a UNIX domain socket to perform authentication, this prevents unprivilged users from accessing the keys used to validate the OTP challenge.

A counter value is computed from the usage counter and timestamp fields of each OTP challenge and synchronized between systems. This synchroization is performed over UDP and protected from forgery using HMAC. This provides robust failure tolerent counter syncronization to prevent replay attacks across multiple hosts.

The motivation of using this approach was to create a two factor authentication system that would not depend on any external services, so it would continue to work in the event of a significant network disruption. The downside of this approach is the authentication secrets must be stored locally on each server.

Installation
------------

Installation via RPM is recommended, but manual installation is possible (see `yubiauthd.spec` -- `%install`). Important details:
+ Install Perl modules from `lib/` somewhere in your Perl include path.
+ Install `src/yubiauthd` server in an approprate sbin like location.
+ Install `src/yubiauth` client in an approprate bin like location.
+ Copy configuration files to `/etc`.
+ Ensure unprivileged users can not access `/etc/yubiauthd.conf`.
+ Ensure unprivileged users can access `/etc/yubiauth.conf`.

Configuration
-------------

For new installations using the `sqlite_store` is recommended. This uses a simple SQLite database to store identities:

    SQLite version 3.7.13 2012-06-11 02:05:22
    Enter ".help" for instructions
    Enter SQL statements terminated with a ";"
    sqlite> .schema
    CREATE TABLE identities (
      public_id TEXT UNIQUE NOT NULL,
      serial_number INTEGER,
      username TEXT UNIQUE NOT NULL,
      aes_key TEXT,
      uid TEXT,
      counter INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP
    );
    sqlite> SELECT * FROM identities;
    vvdfunukiecr|1283724|johndoe|a6f2a101fbb75586da5c0ac073ad7594|163c330ceab7|677001|2013-08-01 20:08:27|2013-08-15 23:45:35

This database is automatically created when `yubiauthd` is first run, but obviously will not include your YubiKey identities. Ensure this database is only accessible by root.

Ensure the `auth_socket` directory exists and is readable by all users.

An example syncronization peer configuration is included in `etc/yubiauthd.conf`. If in a dual stack enviornment, note the difference in behaviour of listening IPv6 sockets.

