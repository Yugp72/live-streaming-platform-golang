import Foundation
import MessagingEngine

class ClientDelegate: MessagingClientDelegate {
    func client(_ client: MessagingClient, didConnect connection: Connection) {
        print("✅ Connected to server")
    }
    
    func client(_ client: MessagingClient, didReceiveMessage message: MessageEnvelope) {
        let payloadString = String(data: message.message.payload, encoding: .utf8) ?? "binary"
        print("📨 Received: \(payloadString)")
    }
    
    func client(_ client: MessagingClient, didReceiveAck ack: MessageAck) {
        print("✅ Message acknowledged: \(ack.messageId) - \(ack.status)")
    }
    
    func client(_ client: MessagingClient, didDisconnect error: Error?) {
        if let error = error {
            print("❌ Disconnected: \(error)")
        } else {
            print("❌ Disconnected")
        }
    }
    
    func client(_ client: MessagingClient, didEncounterError error: Error) {
        print("⚠️ Error: \(error)")
    }
}

let client = MessagingClient()
let delegate = ClientDelegate()
client.delegate = delegate

// Subscribe to messages
_ = client.subscribe(topic: "test") { message in
    print("📬 Topic 'test': \(message.message.id)")
}

print("🔌 Connecting to server...")
client.connect(host: "localhost", port: 8080)

// Wait for connection
Thread.sleep(forTimeInterval: 1.0)

// Send test messages
print("\n📤 Sending test messages...")

let messages = [
    ("Hello, World!", StandardMessage.MessagePriority.low),
    ("High priority message", StandardMessage.MessagePriority.high),
    ("Critical alert!", StandardMessage.MessagePriority.critical),
]

for (text, priority) in messages {
    let payload = text.data(using: String.Encoding.utf8)!
    let message = StandardMessage(
        payload: payload,
        topic: "test",
        priority: priority
    )
    let envelope = MessageEnvelope(
        message: message,
        source: "client-\(UUID().uuidString.prefix(8))"
    )
    
    do {
        try client.send(envelope)
        print("  ✓ Sent: \(text)")
    } catch {
        print("  ✗ Failed to send: \(error)")
    }
    
    Thread.sleep(forTimeInterval: 0.5)
}

print("\n⏳ Waiting for responses...")
Thread.sleep(forTimeInterval: 2.0)

client.disconnect()
print("👋 Disconnected")

