Synchronization Protocol
========================

This document describes the protocol used to synchronize YubiKey counter
updates.

Synchronization Message Format
------------------------------

Synchronization messages are sent as UDP datagrams, the payload of these
datagrams is exactly 36 bytes.

      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                                                               |
     +                                                               +
     |                       Public Identity                         |
     +                                                               +
     |                                                               |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                        Counter Value                          |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
     |                                                               |
     +                                                               +
     |                                                               |
     +                                                               +
     |                       SHA1 HMAC Digest                        |
     +                                                               +
     |                                                               |
     +                                                               +
     |                                                               |
     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

Fields:

    Public Identity
                The public identity for which we are incrementing the counter
                in the original mod hex encoding.

    Counter Value
                The new counter value for this public identity expressed as
                as 32bit integer in network byte order.

    SHA1 HMAC Digest
                The SHA1 HMAC Digest of the shared key, public identity and
                counter value.
