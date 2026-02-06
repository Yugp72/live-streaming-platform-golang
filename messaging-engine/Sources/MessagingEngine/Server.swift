import Foundation
import Network

/// Server delegate protocol
public protocol MessagingServerDelegate: AnyObject {
    func server(_ server: MessagingServer, didAcceptConnection connection: Connection)
    func server(_ server: MessagingServer, didReceiveMessage message: MessageEnvelope, from connection: Connection)
    func server(_ server: MessagingServer, connectionDidDisconnect connection: Connection)
}

/// TCP/IP messaging server with connection pooling
public class MessagingServer {
    public weak var delegate: MessagingServerDelegate?
    
    private let listener: NWListener
    private let queue: DispatchQueue
    private var connections: [UUID: Connection] = [:]
    private let messageQueue: MessageQueue
    private let messageStream: MessageStream
    private let lock = NSLock()
    private var isRunning = false
    
    public init(port: UInt16 = 8080, queue: DispatchQueue = DispatchQueue(label: "com.messaging.server")) {
        self.queue = queue
        self.messageQueue = MessageQueue()
        self.messageStream = MessageStream()
        
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = false
        
        // Optimize for low latency
        if let options = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            options.version = .v4
        }
        
        let port = NWEndpoint.Port(rawValue: port)!
        listener = try! NWListener(using: parameters, on: port)
        
        setupMessageHandling()
    }
    
    private func setupMessageHandling() {
        // Setup message queue processing
        messageQueue.onMessage = { [weak self] envelope in
            guard let self = self else { return }
            // Process message through stream
            self.messageStream.publish(envelope)
        }
    }
    
    public func start() throws {
        guard !isRunning else { return }
        
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }
        
        listener.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                print("Server listening on port \(self.listener.port?.rawValue ?? 0)")
                self.isRunning = true
            case .failed(let error):
                print("Server failed: \(error)")
                self.isRunning = false
            default:
                break
            }
        }
        
        listener.start(queue: queue)
    }
    
    private func handleNewConnection(_ nwConnection: NWConnection) {
        let connection = Connection(connection: nwConnection, queue: queue)
        connection.delegate = self
        
        lock.lock()
        connections[connection.connectionId] = connection
        lock.unlock()
        
        delegate?.server(self, didAcceptConnection: connection)
        connection.start()
    }
    
    public func stop() {
        isRunning = false
        listener.cancel()
        
        lock.lock()
        let allConnections = connections.values
        lock.unlock()
        
        for connection in allConnections {
            connection.disconnect()
        }
        
        lock.lock()
        connections.removeAll()
        lock.unlock()
    }
    
    /// Broadcast message to all connected clients
    public func broadcast(_ envelope: MessageEnvelope) {
        lock.lock()
        let allConnections = connections.values
        lock.unlock()
        
        let frame = ProtocolFrame(
            type: .message,
            payload: try! JSONEncoder().encode(envelope),
            sequenceNumber: 0
        )
        
        for connection in allConnections {
            try? connection.send(frame: frame)
        }
    }
    
    /// Send message to specific connection
    public func send(_ envelope: MessageEnvelope, to connectionId: UUID) throws {
        lock.lock()
        guard let connection = connections[connectionId] else {
            lock.unlock()
            throw ProtocolError.connectionError("Connection not found")
        }
        lock.unlock()
        
        let frame = ProtocolFrame(
            type: .message,
            payload: try JSONEncoder().encode(envelope),
            sequenceNumber: 0
        )
        
        try connection.send(frame: frame)
    }
    
    /// Subscribe to message stream
    public func subscribe(topic: String? = nil, handler: @escaping (MessageEnvelope) -> Void) -> String {
        return messageStream.subscribe(topic: topic, handler: handler)
    }
}

extension MessagingServer: ConnectionDelegate {
    public func connection(_ connection: Connection, didReceiveFrame frame: ProtocolFrame) {
        switch frame.type {
        case .message:
            handleMessage(frame, from: connection)
        case .heartbeat:
            // Echo heartbeat
            try? connection.send(frame: ProtocolFrame(
                type: .heartbeat,
                payload: Data(),
                sequenceNumber: frame.sequenceNumber
            ))
        case .subscribe:
            // Handle subscription
            break
        case .unsubscribe:
            // Handle unsubscription
            break
        default:
            break
        }
    }
    
    private func handleMessage(_ frame: ProtocolFrame, from connection: Connection) {
        do {
            let envelope = try JSONDecoder().decode(MessageEnvelope.self, from: frame.payload)
            
            // Enqueue for processing
            messageQueue.enqueue(envelope)
            
            // Notify delegate
            delegate?.server(self, didReceiveMessage: envelope, from: connection)
            
            // Send acknowledgment
            let ack = MessageAck(messageId: envelope.message.id, status: .delivered)
            let ackFrame = ProtocolFrame(
                type: .ack,
                payload: try JSONEncoder().encode(ack),
                sequenceNumber: frame.sequenceNumber
            )
            try? connection.send(frame: ackFrame)
        } catch {
            print("Error handling message: \(error)")
        }
    }
    
    public func connection(_ connection: Connection, didChangeState state: ConnectionState) {
        if state == .disconnected {
            lock.lock()
            connections.removeValue(forKey: connection.connectionId)
            lock.unlock()
            delegate?.server(self, connectionDidDisconnect: connection)
        }
    }
    
    public func connection(_ connection: Connection, didEncounterError error: Error) {
        print("Connection error: \(error)")
    }
}

