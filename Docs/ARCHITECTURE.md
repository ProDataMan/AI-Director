# Architecture

This document tracks the implemented architecture of AI Director.

## Current implementation status

The repository currently contains the initial Swift package foundation and the first OBS protocol layer.

Implemented modules:

- `StudioCore` — foundational domain types
- `OBSKit` — OBS WebSocket v5 message models and transport skeleton
- `StudioDirector` — initial orchestration actor placeholder
- `AIKit` — AI provider protocol placeholder
- `RecordingKit` — recording module placeholder

## Current dependency graph

```text
StudioCore
   |
   +----> OBSKit
   |
   +----> AIKit
   |
   +----> RecordingKit
              |
              v
        StudioDirector
```

`StudioDirector` depends on StudioCore, OBSKit, AIKit, and RecordingKit.

## Implemented domain types

- StudioState
- SceneRole
- CameraShot
- RGBColor
- ColorPalette

All current StudioCore domain types are Codable, Sendable, and Equatable where appropriate.

## OBS protocol layer

OBSKit currently implements typed models for core obs-websocket v5 envelopes:

- Hello
- Identify
- Identified
- Request
- RequestResponse
- Event

A generic `JSONValue` type is used for unmodeled OBS request/response payload dictionaries while the project transitions toward operation-specific DTOs.

## OBS transport

`OBSWebSocketClient` is an actor backed by `URLSessionWebSocketTask`.

Current capabilities:

- create and resume a WebSocket task
- track basic connection state
- send Encodable values as JSON text frames
- run a receive loop
- disconnect cleanly

Not implemented yet:

- Hello/Identify handshake state machine
- OBS authentication challenge hashing
- request/response correlation
- event delivery
- timeouts
- reconnect behavior

These are the next OBSKit tasks.

## Testing

The current test suite verifies:

- StudioState Codable round trip
- ColorPalette Codable round trip
- Hello decoding without authentication
- Hello decoding with authentication
- Identify encoding
- RequestResponse decoding
- Event decoding

The bootstrap was validated locally with Swift 6.2.1 and `swift test`.

## Next architectural step

Complete Milestone 2 by turning `OBSWebSocketClient` from a transport skeleton into a fully negotiated OBS WebSocket v5 client:

1. decode incoming opcodes
2. process Hello
3. calculate authentication response when required
4. send Identify
5. wait for Identified
6. correlate request IDs with continuations
7. expose event streams
8. add timeout and connection errors
