import Foundation
import MessagingEngine

class ServerDelegate: MessagingServerDelegate {
    func server(_ server: MessagingServer, didAcceptConnection connection: Connection) {
        print("✅ New connection: \(connection.connectionId)")
    }
    
    func server(_ server: MessagingServer, didReceiveMessage message: MessageEnvelope, from connection: Connection) {
        let payloadString = String(data: message.message.payload, encoding: .utf8) ?? "binary"
        print("📨 Received message [\(message.message.priority)] from \(message.source): \(payloadString)")
    }
    
    func server(_ server: MessagingServer, connectionDidDisconnect connection: Connection) {
        print("❌ Connection disconnected: \(connection.connectionId)")
    }
}

let server = MessagingServer(port: 8080)
let delegate = ServerDelegate()
server.delegate = delegate

// Subscribe to all messages
let subscriptionId = server.subscribe { envelope in
    print("📬 Stream message: \(envelope.message.id)")
}

print("🚀 Starting messaging server on port 8080...")
print("Press Ctrl+C to stop")

do {
    try server.start()
    
    // Keep server running
    RunLoop.main.run()
} catch {
    print("❌ Failed to start server: \(error)")
    exit(1)
}

