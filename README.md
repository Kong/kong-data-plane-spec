# Kong data-plane spec

This specification defines the protocols and behaviors used by Kong gateway
data-plane and control-plane to communicate with each other.

The data-plane sets the specification and control-plane follows the specification.

There are two parts to the Kong data-plane specification:
- [wRPC](./wrpc): a custom RPC protocol. wRPC is designed with
  constraints of Kong's technology stack in mind. It is independent of the
  spec and can be used for any other workload. The data-plane specification is
  built on top of wRPC.
- [spec](./spec): specification for integrating with a Kong DP.

This spec is implemented in Kong Gateway 3.0 and will undergo minor changes
with the development of 3.x series.

Control-plane implementations of this spec are encouraged. If you are
interested in building one or happen to run into problems with the spec, please
open a Github Issue.

