import Foundation
import MessagingEngine

class StreamingEventSubscriber: MessagingClientDelegate {
    private let client: MessagingClient
    
    init() {
        self.client = MessagingClient()
        self.client.delegate = self
    }
    
    func start() {
        print("🔌 Connecting to messaging engine...")
        client.connect(host: "localhost", port: 8080)
        
        // Wait for connection
        Thread.sleep(forTimeInterval: 1.0)
        
        // Subscribe to streaming events
        print("📡 Subscribing to streaming events...")
        _ = client.subscribe(topic: "streaming.events") { [weak self] envelope in
            self?.handleStreamingEvent(envelope)
        }
        
        print("✅ Subscribed! Waiting for events...")
        print("Press Ctrl+C to exit\n")
    }
    
    private func handleStreamingEvent(_ envelope: MessageEnvelope) {
        guard let eventJSON = String(data: envelope.message.payload, encoding: .utf8) else {
            return
        }
        
        // Parse streaming event
        if let eventData = eventJSON.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: eventData) as? [String: Any],
           let eventType = json["type"] as? String,
           let channel = json["channel"] as? String {
            
            let timestamp = json["timestamp"] as? String ?? "unknown"
            let data = json["data"] as? [String: Any] ?? [:]
            
            displayEvent(type: eventType, channel: channel, timestamp: timestamp, data: data)
        }
    }
    
    private func displayEvent(type: String, channel: String, timestamp: String, data: [String: Any]) {
        let emoji = emojiForEventType(type)
        let time = formatTimestamp(timestamp)
        
        print("\n\(emoji) [\(time)] Event: \(type)")
        print("   Channel: \(channel)")
        
        if !data.isEmpty {
            print("   Data:")
            for (key, value) in data {
                print("     - \(key): \(value)")
            }
        }
        print()
    }
    
    private func emojiForEventType(_ type: String) -> String {
        switch type {
        case "stream.started": return "🎬"
        case "stream.stopped": return "🛑"
        case "stream.playing": return "▶️"
        case "viewer.joined": return "👤"
        case "viewer.left": return "👋"
        case "hls.ready": return "📺"
        case "hls.segment.ready": return "📦"
        default: return "📨"
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "HH:mm:ss"
            return displayFormatter.string(from: date)
        }
        return timestamp
    }
    
    // MARK: - MessagingClientDelegate
    
    func client(_ client: MessagingClient, didConnect connection: Connection) {
        print("✅ Connected to messaging engine")
    }
    
    func client(_ client: MessagingClient, didReceiveMessage message: MessageEnvelope) {
        // Handled in subscription callback
    }
    
    func client(_ client: MessagingClient, didReceiveAck ack: MessageAck) {
        // Ignore acks for now
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

// Main
let subscriber = StreamingEventSubscriber()
subscriber.start()

// Keep running
RunLoop.main.run()

