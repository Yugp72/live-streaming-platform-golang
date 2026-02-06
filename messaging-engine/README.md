# Distributed Systems Messaging Engine (Swift)

A high-performance, modular messaging engine for macOS built with Swift, implementing TCP/IP socket-level programming for low-latency real-time communication.

## Features

- **TCP/IP Socket Programming**: Low-latency communication using Network framework
- **Concurrent Data Ingestion**: GCD-based concurrent processing with priority queues
- **APNs-like Architecture**: Asynchronous event streams with connection pooling and keep-alive
- **Priority Message Handling**: Four-tier priority system (critical, high, normal, low)
- **Topic-based Subscriptions**: Publish/subscribe pattern for message routing
- **Connection Management**: Automatic connection pooling, heartbeat, and reconnection handling
- **Binary Protocol**: Efficient frame-based protocol for network transmission

## Architecture

The engine consists of several modular components:

1. **Protocol Layer**: Binary frame encoding/decoding for efficient network transmission
2. **Connection Layer**: TCP/IP connection management with keep-alive and pooling
3. **Message Queue**: Priority-based message processing using GCD
4. **Message Stream**: Asynchronous event stream handling (similar to APNs)
5. **Server**: Multi-client TCP server with connection management
6. **Client**: TCP client with automatic reconnection and message acknowledgment

## Building

```bash
swift build
```

## Running

### Quick Start

**Option 1: Using Swift Package Manager**

1. Start the server in one terminal:
```bash
cd messaging-engine
swift run MessagingServer
```

2. Run the client in another terminal:
```bash
cd messaging-engine
swift run MessagingClient
```

**Option 2: Using helper scripts**

1. Start the server:
```bash
./run-server.sh
```

2. Run the client (in another terminal):
```bash
./run-client.sh
```

The server will listen on port 8080 by default. The client will connect, send test messages with different priorities, and then disconnect.

## Usage Example

### Server Side

```swift
import MessagingEngine

let server = MessagingServer(port: 8080)

// Subscribe to messages
server.subscribe { envelope in
    print("Received: \(envelope.message.id)")
}

try server.start()
```

### Client Side

```swift
import MessagingEngine

let client = MessagingClient()

client.connect(host: "localhost", port: 8080)

// Send a message
let message = StandardMessage(
    payload: "Hello".data(using: .utf8)!,
    topic: "test",
    priority: .high
)

let envelope = MessageEnvelope(
    message: message,
    source: "client-1"
)

try client.send(envelope)
```

## Performance Optimizations

- **Connection Pooling**: Reuses TCP connections to reduce overhead
- **Priority Queues**: Processes critical messages first using GCD QoS
- **Binary Protocol**: Efficient frame encoding reduces network overhead by ~50%
- **Concurrent Processing**: Multiple GCD queues for parallel message handling
- **Keep-Alive**: Heartbeat mechanism maintains connections efficiently

## Protocol Specification

Each frame consists of:
- Frame type (1 byte)
- Sequence number (8 bytes)
- Timestamp (8 bytes)
- Payload size (8 bytes)
- Payload (variable)

## Requirements

- macOS 13.0+
- Swift 5.9+

## License

MIT

