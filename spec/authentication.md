# Authentication

## Background

A control-plane (CP) and data-plane (DP) need to know if they can trust the
other party or not. This document elaborates on how trust is established between
a DP and CP.

## Note: Separation of encryption and authentication

It should be noted that conceptually authentication and encryption are two
different aspects of a protocol.
Sometimes, TLS with client-certificates (a.k.a. mTLS) might be used for
authentication _and_ encryption. This is an implementation detail that
mixes the two - a side-effect and nothing more.

Please refer to [protocol.md](protocol.md) for details on how the spec uses
TLS. For the purpose of this document, it can be assumed that TLS encryption
exists for **all** communication between the CP and DP, including the
authentication flow below.

With that out of our way, let us focus on authentication.

## DP validating CP

To assert CP's identity, a DP MUST verify that the TLS certificate present by
the CP is signed by a CA it trusts. The hostname (FQDN) used to resolve CP's
IP address MUST match the SNI used in TLS handshake, which in turn MUST be
present in the TLS certificate's SAN field. This MUST be performed every time
a connection is established between a CP and a DP.

This is the only mechanism DP has to validate the identity of the CP and trust
it.

## CP authentication DP

Only a single authentication method is supported as of today.
Additional authentication method may be added in the future.

#### Client certificate

Client certificate, also popularly known as mTLS use TLS certificates and TLS
session handshake for authentication of clients. When this authentication
scheme is used, DP MUST provide the client certificate during TLS negotiation.
CP MAY chose to terminate the connection if the client certificate verification
fails, and DP MUST expect this behavior from the CP.

In this scheme, TLS sessions are considered as trusted from CP's point of view.
No additional authentication information is included in any HTTP request that
is issued on top of authenticated TLS sessions.

The spec is not prescriptive of CP behaviors.
CP may choose to implement PKI workflows to perform client-certificate based
authentication or it may choose any other workflow.

## Authorization

Authorization isn't a part of the specification currently. It MAY
be added in future as use-cases are discovered.

