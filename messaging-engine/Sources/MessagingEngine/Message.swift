import Foundation

/// Message protocol for the messaging engine
public protocol Message: Codable {
    var id: UUID { get }
    var timestamp: Date { get }
    var payload: Data { get }
}

/// Standard message implementation
public struct StandardMessage: Message {
    public let id: UUID
    public let timestamp: Date
    public let payload: Data
    public let topic: String?
    public let priority: MessagePriority
    
    public enum MessagePriority: Int, Codable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
    }
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        payload: Data,
        topic: String? = nil,
        priority: MessagePriority = .normal
    ) {
        self.id = id
        self.timestamp = timestamp
        self.payload = payload
        self.topic = topic
        self.priority = priority
    }
}

/// Message envelope for network transmission
public struct MessageEnvelope: Codable {
    public let message: StandardMessage
    public let source: String
    public let destination: String?
    public let metadata: [String: String]
    
    public init(
        message: StandardMessage,
        source: String,
        destination: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.message = message
        self.source = source
        self.destination = destination
        self.metadata = metadata
    }
}

/// Message acknowledgment
public struct MessageAck: Codable {
    public let messageId: UUID
    public let status: AckStatus
    public let timestamp: Date
    
    public enum AckStatus: String, Codable {
        case delivered
        case failed
        case pending
    }
    
    public init(messageId: UUID, status: AckStatus, timestamp: Date = Date()) {
        self.messageId = messageId
        self.status = status
        self.timestamp = timestamp
    }
}

