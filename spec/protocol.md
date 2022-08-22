# DP-spec - Protocol

This document explains the protocols used at various levels of the networking
stack.

## TCP/IP

TCP is used as the L4 transport protocol. It is the only supported protocol
at this level.

## TLS

TLS is used for as an encryption layer. The spec relies on TLS for
confidentiality of the data. TLS version 1.1 is NOT supported. Compatible
versions are TLS 1.2 and 1.3. Certificate verification for TLS certificate
SHOULD be enabled by the implementation - it is strongly discouraged to disable
verification as TLS certificate is the only mechanism in the protocol to assert
the identity of a control-plane(CP).
SNI support is expected from all software (including network proxies) involved.

In some cases, TLS may be used for authentication. That is considered
orthogonal to the use of TLS for confidentiality of data.

## HTTP

HTTP is used for upgrades to wRPC currently. 
Use of HTTP MAY be expanded in future.
Additional RPCs using HTTP request/response lifecycles (in addition to WebSockets)
are allowed.

It is expected that all layers up until this point will always remain part of
this specification. Future iterations may use a different RPC protocol and the
versatile nature of HTTP will help us swap out layers at a higher level
if needed.

HTTP requests are considered stateless. Any service that is designed MUST take
into account multiple CP nodes. This spec does NOT dictate that HTTP requests
originating from a DP node always land up on the same CP node. This is at
odds with [Proxy capabilities](protocol.md#proxy-capabilities), where it is
explicitly noted that L7 proxies in between CP and DP are not allowed.
The guidance here is for Kong maintainers where as the guidance in the 
other document is for end-users.

### Required headers

The following headers are required in each HTTP request that DP initiates:
- `kong-node-id`: header containing the Node ID of the DP node
- `kong-version`: header containing the version of Kong on the DP node
- `kong-hostname`: header containing the hostname of the underlying node

CP is required to add its node-iD in the
`kong-node-id` header in response to each and every HTTP response.

## wRPC

wRPC is the RPC layer that is used for communicating with a Kong DP. wRPC
streams are considered authenticated and trusted.

A wRPC connection is between a DP and a CP node. There is no load-balancing or
splitting of stream that is allowed for a wRPC connection.

## Misc

### Connection limits

A single DP is allowed and will often establish multiple connections to a CP.
CP MAY limit the number of TCP connections from a single DP.

### Proxy capabilities

This section elaborate on how proxies in between a DP and CP can operate.
Please read this section carefully if you wish to put a network proxy above
Layer 4 (of OSI model, TCP in our case):
- As far as network proxies that sit between DP and CP, the communication
  protocol in use is custom and not HTTP. It is assumed that the network
  proxies are operating at layer 4 of the OSI model.
- Network proxies between the DP and CP MAY operate at TLS layer. This is
  strongly discouraged and an operator should do this only if they know what
  they are doing. A misconfiguration can seriously jeopardize the security of
  the protocol as this protocol uses TLS for confidentiality. If mTLS is being
  used for authenticating DP, introduce a TLS terminating network proxy between
  a CP and DP significantly increases operational complexity and it is strongly
  recommended to not pursue such a deployment model.
- Even though the protocol uses HTTP internally, a network proxy between the DP
  and CP is not allowed to interpret the HTTP request/response envelope. The
  protocol MAY work if this is done. This is considered as a side-effect.
- HTTP PROXY using CONNECT method as defined in [RFC
  7231](https://datatracker.ietf.org/doc/html/rfc7231#section-4.3.6) is
  permitted. The proxy (or proxies) in this case MUST NOT interpret bytes that
  are flowing via the tunnel.

Violation of any of the above implies that this protocol could become unstable.
Support guarantees in this case won't be entertained.

