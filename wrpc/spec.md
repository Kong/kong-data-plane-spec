# wRPC - wRPC Remote Procedure Calls

This document defines the wRPC protocol.

> Note: Why we do this is out of scope of this document. If you are interested
in that, please refer to the ADR-000X. TODO(hbagdi): Add in the link.

## Introduction

wRPC protocol is implemented on top of binary WebSocket messages.
The protocol is bidirectional meaning requests can originate from either end
of a connection. Requests are initiated by a sender sending a messsage containing
the metadata identifying the RPC the sender wishes to invoke, its arguments and
an identifier. The receiver processes the request and sends back a messsage
containing the result of the RPC call alongwith the identifier from the request.
The identifier is then used by the sender to tie the response back to the
request it has issued earlier.

## Protocol layering

The layers within this protocols are:

```
wRPC - protocol described here
WebSocket - bidirectional transport stream on top of HTTP (similar to TCP)
HTTP - application layer
TLS - encryption layer
TCP - transport layer
```

WebSocket protocol used here is defined in
[RFC 6455](https://datatracker.ietf.org/doc/html/rfc6455). The protocol is
used as without any exception.
Each WebSocket connection (post upgrade) is referred to as "connection" within
this document.

HTTP, TLS and TCP are used to take advantage of existing HTTP infrastructure.

## Connection establishment

wRPC runs on top of WebSocket connections. This section describes the specifics
of how a WebSocket connection MUST be established before it can be used for
wRPC.

wRPC makes use WebSocket's `Sec-WebSocket-Version` header for version
negotiation as defined in [Section 4.4 of RFC
6455](https://datatracker.ietf.org/doc/html/rfc6455#section-4.4).
The client MUST set `Sec-WebSocket-Version` header to the value
`wrpc.konghq.com` in its handshake request for an upgrade.
The server MUST check for the existence of the header value in the upgrade
request before upgrading and include the same header in its response to the
client. If The header is not present, the server MUST respond back in
accordance with with RFC 6455 (400 with the header set to version the server
supports).  This mechanism will be used in future to introduce new versions of
wRPC.

The following examples illustrate a successful version negotiation:

```
Request:

GET /v1/wrpc HTTP/1.1
Host: server.example.com
Upgrade: websocket
Connection: Upgrade
...
Sec-WebSocket-Version: wrpc.konghq.com

Response:

HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
...
Sec-WebSocket-Protocol:  wrpc.konghq.com

```

wRPC dictates nothing in addition to the above requirement to establish a
wRPC connection.
Once a wRPC connection has been established using the above mechanism,
the two parties sharing the connection can start invoking RPCs.

## Concurrency

Two applications are allowed to share multiple WebSocket connections. There
is no shared state between two connections at the protocol level.

Within a single connection, a sender CAN send multiple concurrent requests to
the receiver. Requests are delivered to the receiver in the order they are
sent. This is governed by the semantics of the underlying WebSocket connection.
The receiver is free to process the received requests in any order. wRPC
imposes no behavior and applications MAY impose stricter ordering flows as
necessary.

## Interface definition language

wRPC uses Protocol Buffer (protobuf)
[version3](https://developers.google.com/protocol-buffers/docs/proto3) to define
Services. Please note that gRPC is a popular RPC framework that also uses
protobuf under the hood. wRPC is not related to gRPC otherwise.
Please note that only unary RPCs are supported at the moment. Streaming is not
supported but may be added in a future version.

In addition to the regular protobuf definition, there are two additional bits of
data:
- **Service ID**: Each protobuf `service` MUST have a unique ID. An ID is a
  positive 32-bit integer greater than 1. An ID for a Service is define via a
  doc line of the form: `// +wrpc:service-id=<id>`, where `<id>` is
  substituted by the unique integer.
- **RPC ID**: Each protobuf `rpc` within a `service` MUST have a unique ID. An
  ID is a positive 32-bit integer greater than 1. An ID for an RPC is define
  via a doc line of the form: `// +wrpc:rpc-id=<id>`, where `<id>` is
  substituted by the unique integer.

## Request-response flow

This section describes the request/response flow of a wRPC call.

### Encoding

wRPC uses protobuf encoded binary WebSocket messages to exchange data between
two peers. The encoding for these messages is defined in [wrpc.proto](wrpc.proto) file.

### Flow

Requests are initiated by a sender sending a message containing the metadata
identifying the RPC the sender wishes to invoke, its arguments and a sequence
number. The receiver processes the request and sends back a message containing
the result of the RPC call along-with the ack set to the sequence number from
the request.

An example flow:

The below request calls RPC with rpc-id of 7 in service with service-id of 42:

```
Request:

  version = 1
  payload ->
    mtype = 2
    svc_id = 42
    rpc_id = 7
    seq = 30
    ack = 0
    deadline = 30
    payload_encoding = 1
    payloads = <payloads for the RPC request>

Response:

  version = 1
  payload ->
    mtype = 2
    svc_id = 42
    rpc_id = 7
    seq = 25
    ack = 30
    deadline = 0
    payload_encoding = 1
    payloads = <payloads for the RPC response>
```

Notice how:
- Sequence numbers uniquely identify messages from flowing from one peer to other
- Ack is set to the sequence number of the request messages, this is how the sender
  ties back the response to the request

Please refer to [wrpc.proto](wrpc.proto) file for details on how various fields
are set and error signals takes place.

## Stream flow

This section describes the stream flow within the context of a wRPC call.
Similar to gRPC, wRPC also supports bidirectional streaming.

A stream is always in the context of a RPC call - meaning if an RPC call or connection
terminates, so does the stream. A stream can be started by
the sender or the receiver of an RPC call or both.
An RPC defined as stream of requests/responses MUST begin with a control message.
For any end(sender/receiver of the RPC) to start streaming , the first message
is a control message with `mtype` set to STREAM_BEGIN with `stream_id` set
to the same value as the `seq` of this control message. For the duration of the
stream, each message sent by the sender MUST contain the same `stream_id`. Once
the sender is done, it MUST send another control-message with `mtype` set to
STREAM_END with the same `stream_id`. For bidirectional streams or streams from
receiver (of the RPC) to sender, the receiver starts the stream in the response
to the control message or request from the sender.

Receiver of stream messages MUST drop any message with a stream_id for which it
has not received a STREAM_BEGIN yet. Messages within a stream are ordered -
wRPC relies on the ordering properties of HTTP WebSocket messages for this
purpose. After receiving a STREAM_END, the receiver can drop any message tied
to the same stream.

There is no flow-control built into the protocol. Implementations will likely
need to rely on the underlying network buffers for this purpose. Messages
within a stream may be lost due to a network interruptions - there is no
acknowledgement built into the protocol. Applications may implement acks if
required in the application-layer code.

### Flow

Here is an example of a stream:

```
Stream-begin message:

  version = 1
  payload ->
    mtype = 3
    svc_id = 42
    rpc_id = 8
    seq = 30
    stream_id = 30
    ack = 0
    deadline = 0
    payload_encoding = 0
    payloads = <payload MUST be empty>

Stream:

  version = 1
  payload ->
    mtype = 4
    svc_id = 42
    rpc_id = 8
    stream_id = 30
    seq = 31
    ack = 0
    deadline = 0
    payload_encoding = 1
    payloads = <payload message>

  version = 1
  payload ->
    mtype = 4
    svc_id = 42
    rpc_id = 8
    seq = 32
    stream_id = 30
    ack = 0
    deadline = 30
    payload_encoding = 1
    payloads = <payload message>

  version = 1
  payload ->
    mtype = 4
    svc_id = 42
    rpc_id = 8
    seq = 33
    stream_id = 30
    ack = 0
    deadline = 30
    payload_encoding = 1
    payloads = <payload message>

Stream-end message:

  version = 1
  payload ->
    mtype = 5
    svc_id = 42
    rpc_id = 8
    seq = 33
    stream_id = 30
    ack = 0
    deadline = 30
    payload_encoding = 1
    payloads = <payload message>
```

## Misc

This section details various miscellaneous details.

### Protocol error handling

In case of protocol errors such as invalid encoding, invalid wRPC payload,
receiver SHOULD send an error message to the sender and then the receiver MUST
close the connection. On such errors, it is recommended that the sender does not
retry with the exact same payloads/encoding since it is unlikely to resolve the
problem without any human intervention.

### Authentication

Authentication is not part of the protocol and MUST be performed in one of the
following two ways:
- at a lower layer such as HTTP or TLS
- via a wRPC call

### Stateful/stateless balance

wRPC protocol is designed to minimize the amount of state storage required in
any part of the infrastructure. The protocol expects applications to hold the
following state:
- outstanding request/responses on a connection
- sequence number associated with the connection
- metadata describing the RPCs being invoked on the connection (proto files)

The protocol DOES NOT require applications to hold any state outside the
context of a connection.

### Request prioritization

wRPC has no notion of RPC/Service priorities or Quality of Service (QoS).
Applications are free to define priority ordering on top of the protocol if
they wish to.

### Head Of Line blocking

wRPC allows for concurrent requests on the same wRPC connection and allows for
multiple wRPC connections between two peers. In this regard, multiplexing is
possible and head of line issues are not present in wRPC.

However, similar to HTTP/2 HTTP WebSockets, wRPC faces head of line blocking
issues at the TCP-level.

