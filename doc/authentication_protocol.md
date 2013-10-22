
Authentication Protocol
=======================

To validate a YubiKey OTP a user program connects to the authentication socket
and sends the one time password. After the complete password is received
yubiauthd responds with either 'DENIED' or 'AUTHENTICATION SUCCESSFUL'.
