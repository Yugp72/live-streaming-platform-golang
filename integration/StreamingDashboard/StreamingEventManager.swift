import Foundation
import SwiftUI
import MessagingEngine

class StreamingEventManager: ObservableObject {
    @Published var recentEvents: [StreamingEvent] = []
    @Published var channels: [String: ChannelData] = [:]
    @Published var isConnected = false
    @Published var totalEvents = 0
    @Published var activeStreams = 0
    @Published var totalViewers = 0
    
    private var client: MessagingClient?
    private var subscriptionId: String?
    private let maxEvents = 100
    
    struct StreamingEvent: Identifiable {
        let id = UUID()
        let type: EventType
        let channel: String
        let timestamp: Date
        let data: [String: String]
    }
    
    enum EventType: String {
        case streamStarted = "stream.started"
        case streamStopped = "stream.stopped"
        case streamPlaying = "stream.playing"
        case viewerJoined = "viewer.joined"
        case viewerLeft = "viewer.left"
        case hlsReady = "hls.ready"
        case hlsSegmentReady = "hls.segment.ready"
    }
    
    struct ChannelData {
        var isActive: Bool = false
        var viewerCount: Int = 0
        var lastEvent: Date?
    }
    
    func connect(host: String, port: Int) {
        let newClient = MessagingClient()
        newClient.delegate = self
        self.client = newClient
        
        newClient.connect(host: host, port: port)
        
        // Wait a bit for connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.subscriptionId = newClient.subscribe(topic: "streaming.events") { [weak self] envelope in
                self?.handleEvent(envelope)
            }
            self.isConnected = true
        }
    }
    
    func disconnect() {
        // Note: MessagingClient doesn't have unsubscribe yet, but subscription is tied to client
        client?.disconnect()
        client = nil
        subscriptionId = nil
        isConnected = false
    }
    
    func clearEvents() {
        recentEvents.removeAll()
        channels.removeAll()
        totalEvents = 0
        activeStreams = 0
        totalViewers = 0
    }
    
    private func handleEvent(_ envelope: MessageEnvelope) {
        guard let eventJSON = String(data: envelope.message.payload, encoding: .utf8),
              let jsonData = eventJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let typeString = json["type"] as? String,
              let eventType = EventType(rawValue: typeString),
              let channel = json["channel"] as? String else {
            return
        }
        
        let timestamp: Date
        if let timestampString = json["timestamp"] as? String {
            let formatter = ISO8601DateFormatter()
            timestamp = formatter.date(from: timestampString) ?? Date()
        } else {
            timestamp = Date()
        }
        
        var data: [String: String] = [:]
        if let dataDict = json["data"] as? [String: Any] {
            for (key, value) in dataDict {
                data[key] = "\(value)"
            }
        }
        
        let event = StreamingEvent(
            type: eventType,
            channel: channel,
            timestamp: timestamp,
            data: data
        )
        
        DispatchQueue.main.async {
            self.recentEvents.insert(event, at: 0)
            if self.recentEvents.count > self.maxEvents {
                self.recentEvents.removeLast()
            }
            
            self.totalEvents += 1
            self.updateChannelData(channel: channel, eventType: eventType, data: data)
            self.updateStatistics()
        }
    }
    
    private func updateChannelData(channel: String, eventType: EventType, data: [String: String]) {
        if channels[channel] == nil {
            channels[channel] = ChannelData()
        }
        
        var channelData = channels[channel]!
        channelData.lastEvent = Date()
        
        switch eventType {
        case .streamStarted:
            channelData.isActive = true
            activeStreams = channels.values.filter { $0.isActive }.count
        case .streamStopped:
            channelData.isActive = false
            activeStreams = channels.values.filter { $0.isActive }.count
        case .viewerJoined:
            channelData.viewerCount += 1
        case .viewerLeft:
            channelData.viewerCount = max(0, channelData.viewerCount - 1)
        default:
            break
        }
        
        channels[channel] = channelData
    }
    
    private func updateStatistics() {
        activeStreams = channels.values.filter { $0.isActive }.count
        totalViewers = channels.values.reduce(0) { $0 + $1.viewerCount }
    }
}

extension StreamingEventManager: MessagingClientDelegate {
    func client(_ client: MessagingClient, didConnect connection: Connection) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func client(_ client: MessagingClient, didReceiveMessage message: MessageEnvelope) {
        handleEvent(message)
    }
    
    func client(_ client: MessagingClient, didReceiveAck ack: MessageAck) {
        // Handle acknowledgments if needed
    }
    
    func client(_ client: MessagingClient, didDisconnect error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    func client(_ client: MessagingClient, didEncounterError error: Error) {
        print("Error: \(error)")
    }
}

