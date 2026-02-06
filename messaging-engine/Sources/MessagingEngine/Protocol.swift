import Foundation

/// Protocol frame types for TCP communication
public enum FrameType: UInt8, Codable {
    case message = 0x01
    case ack = 0x02
    case heartbeat = 0x03
    case subscribe = 0x04
    case unsubscribe = 0x05
    case error = 0xFF
}

/// Protocol frame for network transmission
public struct ProtocolFrame: Codable {
    public let type: FrameType
    public let payload: Data
    public let sequenceNumber: UInt64
    public let timestamp: Date
    
    public init(type: FrameType, payload: Data, sequenceNumber: UInt64, timestamp: Date = Date()) {
        self.type = type
        self.payload = payload
        self.sequenceNumber = sequenceNumber
        self.timestamp = timestamp
    }
}

/// Protocol encoder/decoder for binary frames
public class ProtocolCodec {
    private static let headerSize = 25 // 1 (type) + 8 (seq) + 8 (timestamp) + 8 (payload size)
    
    /// Encode a frame to binary data
    public static func encode(_ frame: ProtocolFrame) throws -> Data {
        var data = Data()
        
        // Frame type (1 byte)
        data.append(frame.type.rawValue)
        
        // Sequence number (8 bytes)
        data.append(contentsOf: withUnsafeBytes(of: frame.sequenceNumber.bigEndian) { Data($0) })
        
        // Timestamp (8 bytes - Unix timestamp)
        let timestamp = UInt64(frame.timestamp.timeIntervalSince1970 * 1000) // milliseconds
        data.append(contentsOf: withUnsafeBytes(of: timestamp.bigEndian) { Data($0) })
        
        // Payload size (8 bytes)
        let payloadSize = UInt64(frame.payload.count)
        data.append(contentsOf: withUnsafeBytes(of: payloadSize.bigEndian) { Data($0) })
        
        // Payload
        data.append(frame.payload)
        
        return data
    }
    
    /// Decode binary data to a frame
    public static func decode(_ data: Data) throws -> ProtocolFrame {
        guard data.count >= headerSize else {
            throw ProtocolError.invalidFrame("Frame too short")
        }
        
        var offset = 0
        
        // Frame type
        guard let type = FrameType(rawValue: data[offset]) else {
            throw ProtocolError.invalidFrame("Invalid frame type")
        }
        offset += 1
        
        // Sequence number
        let seqData = data.subdata(in: offset..<offset+8)
        let sequenceNumber = seqData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        offset += 8
        
        // Timestamp
        let timestampData = data.subdata(in: offset..<offset+8)
        let timestampMs = timestampData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        let timestamp = Date(timeIntervalSince1970: Double(timestampMs) / 1000.0)
        offset += 8
        
        // Payload size
        let payloadSizeData = data.subdata(in: offset..<offset+8)
        let payloadSize = payloadSizeData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        offset += 8
        
        // Payload
        guard data.count >= offset + Int(payloadSize) else {
            throw ProtocolError.invalidFrame("Payload incomplete")
        }
        let payload = data.subdata(in: offset..<offset+Int(payloadSize))
        
        return ProtocolFrame(
            type: type,
            payload: payload,
            sequenceNumber: sequenceNumber,
            timestamp: timestamp
        )
    }
}

/// Protocol errors
public enum ProtocolError: Error {
    case invalidFrame(String)
    case encodingError(String)
    case decodingError(String)
    case connectionError(String)
}

