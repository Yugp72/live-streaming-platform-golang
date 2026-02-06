# Usage Examples

## Basic Server Setup

```swift
import MessagingEngine

// Create server on port 8080
let server = MessagingServer(port: 8080)

// Implement delegate
class MyServerDelegate: MessagingServerDelegate {
    func server(_ server: MessagingServer, didAcceptConnection connection: Connection) {
        print("New client connected: \(connection.connectionId)")
    }
    
    func server(_ server: MessagingServer, didReceiveMessage message: MessageEnvelope, from connection: Connection) {
        let text = String(data: message.message.payload, encoding: .utf8) ?? ""
        print("Received: \(text)")
    }
    
    func server(_ server: MessagingServer, connectionDidDisconnect connection: Connection) {
        print("Client disconnected")
    }
}

let delegate = MyServerDelegate()
server.delegate = delegate

// Subscribe to all messages
server.subscribe { envelope in
    print("Stream message: \(envelope.message.id)")
}

// Start server
try server.start()

// Keep running
RunLoop.main.run()
```

## Basic Client Setup

```swift
import MessagingEngine

let client = MessagingClient()

// Implement delegate
class MyClientDelegate: MessagingClientDelegate {
    func client(_ client: MessagingClient, didConnect connection: Connection) {
        print("Connected!")
    }
    
    func client(_ client: MessagingClient, didReceiveMessage message: MessageEnvelope) {
        let text = String(data: message.message.payload, encoding: .utf8) ?? ""
        print("Received: \(text)")
    }
    
    func client(_ client: MessagingClient, didReceiveAck ack: MessageAck) {
        print("Message \(ack.messageId) acknowledged")
    }
    
    func client(_ client: MessagingClient, didDisconnect error: Error?) {
        print("Disconnected")
    }
    
    func client(_ client: MessagingClient, didEncounterError error: Error) {
        print("Error: \(error)")
    }
}

let delegate = MyClientDelegate()
client.delegate = delegate

// Connect
client.connect(host: "localhost", port: 8080)

// Wait for connection
Thread.sleep(forTimeInterval: 1.0)

// Send message with different priorities
let highPriorityMessage = StandardMessage(
    payload: "Important!".data(using: .utf8)!,
    topic: "alerts",
    priority: .high
)

let envelope = MessageEnvelope(
    message: highPriorityMessage,
    source: "client-1"
)

try client.send(envelope)

// Subscribe to specific topic
client.subscribe(topic: "alerts") { message in
    print("Alert received: \(message.message.id)")
}
```

## Advanced: Concurrent Message Processing

The engine automatically handles concurrent processing using GCD:

- **Critical messages**: Processed on `.userInteractive` QoS
- **High priority**: Processed on `.userInitiated` QoS  
- **Normal priority**: Processed on `.default` QoS
- **Low priority**: Processed on `.utility` QoS

Messages are automatically queued and processed in priority order, similar to APNs architecture.

## Connection Pooling

The server automatically manages connections:
- Each client connection is tracked by UUID
- Heartbeat mechanism keeps connections alive
- Automatic cleanup on disconnect
- Broadcast messages to all connected clients

```swift
// Broadcast to all clients
let message = StandardMessage(
    payload: "Broadcast".data(using: .utf8)!,
    priority: .normal
)

let envelope = MessageEnvelope(
    message: message,
    source: "server"
)

server.broadcast(envelope)
```

