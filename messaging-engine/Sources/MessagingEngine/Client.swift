import Foundation
import Network

/// Client delegate protocol
public protocol MessagingClientDelegate: AnyObject {
    func client(_ client: MessagingClient, didConnect connection: Connection)
    func client(_ client: MessagingClient, didReceiveMessage message: MessageEnvelope)
    func client(_ client: MessagingClient, didReceiveAck ack: MessageAck)
    func client(_ client: MessagingClient, didDisconnect error: Error?)
    func client(_ client: MessagingClient, didEncounterError error: Error)
}

/// TCP/IP messaging client
public class MessagingClient {
    public weak var delegate: MessagingClientDelegate?
    
    private var connection: Connection?
    private let queue: DispatchQueue
    private let messageStream: MessageStream
    private var pendingMessages: [UUID: MessageEnvelope] = [:]
    private let lock = NSLock()
    
    public init(queue: DispatchQueue = DispatchQueue(label: "com.messaging.client")) {
        self.queue = queue
        self.messageStream = MessageStream()
        
        // Setup message stream subscription
        _ = messageStream.subscribe { [weak self] envelope in
            guard let self = self else { return }
            self.delegate?.client(self, didReceiveMessage: envelope)
        }
    }
    
    /// Connect to server
    public func connect(host: String, port: UInt16) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        let nwConnection = NWConnection(to: endpoint, using: parameters)
        let connection = Connection(connection: nwConnection, queue: queue)
        connection.delegate = self
        
        self.connection = connection
        connection.start()
    }
    
    /// Disconnect from server
    public func disconnect() {
        connection?.disconnect()
        connection = nil
    }
    
    /// Send a message
    public func send(_ envelope: MessageEnvelope) throws {
        guard let connection = connection else {
            throw ProtocolError.connectionError("Not connected")
        }
        
        // Store pending message
        lock.lock()
        pendingMessages[envelope.message.id] = envelope
        lock.unlock()
        
        let frame = ProtocolFrame(
            type: .message,
            payload: try JSONEncoder().encode(envelope),
            sequenceNumber: 0
        )
        
        try connection.send(frame: frame)
    }
    
    /// Subscribe to topic
    public func subscribe(topic: String, handler: @escaping (MessageEnvelope) -> Void) -> String {
        return messageStream.subscribe(topic: topic, handler: handler)
    }
}

extension MessagingClient: ConnectionDelegate {
    public func connection(_ connection: Connection, didReceiveFrame frame: ProtocolFrame) {
        switch frame.type {
        case .message:
            handleMessage(frame)
        case .ack:
            handleAck(frame)
        case .heartbeat:
            // Echo heartbeat
            try? connection.send(frame: ProtocolFrame(
                type: .heartbeat,
                payload: Data(),
                sequenceNumber: frame.sequenceNumber
            ))
        default:
            break
        }
    }
    
    private func handleMessage(_ frame: ProtocolFrame) {
        do {
            let envelope = try JSONDecoder().decode(MessageEnvelope.self, from: frame.payload)
            messageStream.publish(envelope)
        } catch {
            delegate?.client(self, didEncounterError: error)
        }
    }
    
    private func handleAck(_ frame: ProtocolFrame) {
        do {
            let ack = try JSONDecoder().decode(MessageAck.self, from: frame.payload)
            
            lock.lock()
            pendingMessages.removeValue(forKey: ack.messageId)
            lock.unlock()
            
            delegate?.client(self, didReceiveAck: ack)
        } catch {
            delegate?.client(self, didEncounterError: error)
        }
    }
    
    public func connection(_ connection: Connection, didChangeState state: ConnectionState) {
        switch state {
        case .connected:
            delegate?.client(self, didConnect: connection)
        case .disconnected:
            delegate?.client(self, didDisconnect: nil)
        default:
            break
        }
    }
    
    public func connection(_ connection: Connection, didEncounterError error: Error) {
        delegate?.client(self, didEncounterError: error)
    }
}

