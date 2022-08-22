# DP-spec

DP-spec is a collaborative effort to define an interface for communicating to a
Kong data-plane (DP). In hybrid mode, even though Kong has a notion of CP and
DP, majority of the code is shared. We have run into a slew of problems with
emergent properties due to organic evolution of the product. DP-spec is the
first step towards compartmentalization of the Kong Gateway - a real separation
of Kong DP from its control-plane (CP). We intend to replace the Lua-based CP
as it exists today with a new implementation. Further discussion of CP is out
of scope for this document.

## Goals of the DP-spec

These are some of the goals of authoring the spec (possibly not exhaustive):

1. A well defined interface to communicate with the Kong Gateway.
   Communication includes (not exhaustive):
   - push configuration data to Kong Gateway
   - push code itself from CP to DP
   - collecting metrics data from Kong Gateway
     - Metrics on the Gateway node itself
     - Metrics on the traffic flowing through the Gateway
     - Metrics on legal consumption data
     - Metrics on view of infrastructure around Kong Gateway
   - logs
     - logs of Gateway itself for debugging
     - logs around traffic flowing through the Gateway
   - this list is expected to further expand in future
1. *Versioned*: Evolution of the specification must be possible.
1. *Componentization*: Divide the spec into smaller components so that each
   component can evolve the specification as needed.
1. *Incremental*: It should be possible to implement the spec in the DP in
   matter of weeks and not months. Start small and iterate. Use versioning to
   ship fixes and major changes.

## Clarity

This is a large undertaking and it will often be the case the specification
will not be clear enough. While it is possible to exhaustively define all the
behavior, it is not always feasible or the best use of time.
As the spec is implemented, issues will crop up and they will be addressed as
needed. If anything lacks clarity, please consult the maintainers of the spec
for clarification rather than assuming an implicit behavior.

## Introduction

The specification comprises of several level of details. Each section below
dives into an area and provides pointers for more details.

### Protocols

The protocol used by this spec is wRPC.
wRPC is an RPC protocol on top of HTTP WebSockets. Please refer to the
[wRPC][wrpc] specification for more details.
The protocol assumes TLS encryption for every bit of information that is
exchanged with Kong DP.

Please refer to [protocol.md](protocol.md) for further details.

### Authentication

CP authenticates the DP either using mTLS client-certificates or arbitrary
authentication schemes based on `Authorization` HTTP header. 
Please refer to [authentication](authentication.md) for further details. 
All information flows between a DP and CP take place on top of
authenticated connections or authenticated requests. There is no exception to this rule.

### Version negotiation

During startup, a DP negotiate the service versions to use for communication
with the CP. This handshake enables backward and forward compatibility and
allows DPs and CPs to evolve independently.

Please refer to
[version-negotiation.md](./proto/kong/services/negotiation/v1/version-negotiation.md)
for further details.

### Services

To use any Service, Kong DP upgrades an HTTP connection to wRPC connection.
Please refer to [wRPC spec][wrpc] on how that is performed.

After an upgrade is complete, the following services may be used by a DP or CP:
- [Config](proto/kong/services/config): Config service is used
  for sending configuration from CP to DP.
- [Version Negotiation](proto/kong/services/negotiation): Negotiation service
  helps DP and CP to agree on the set of available services and their versions.
  It must be the first RPC on every wRPC connection.


[wrpc]: ../wrpc
