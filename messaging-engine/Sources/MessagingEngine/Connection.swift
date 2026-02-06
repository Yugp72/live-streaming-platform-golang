import Foundation
import Network

/// Connection state
public enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

/// Connection delegate protocol
public protocol ConnectionDelegate: AnyObject {
    func connection(_ connection: Connection, didReceiveFrame frame: ProtocolFrame)
    func connection(_ connection: Connection, didChangeState state: ConnectionState)
    func connection(_ connection: Connection, didEncounterError error: Error)
}

/// TCP connection handler with keep-alive and connection pooling
public class Connection {
    public weak var delegate: ConnectionDelegate?
    public private(set) var state: ConnectionState = .disconnected
    public let connectionId: UUID
    public let remoteAddress: String
    
    private let connection: NWConnection
    private let queue: DispatchQueue
    private var receiveBuffer = Data()
    private var sequenceNumber: UInt64 = 0
    private var heartbeatTimer: DispatchSourceTimer?
    
    public init(connection: NWConnection, queue: DispatchQueue = DispatchQueue(label: "com.messaging.connection")) {
        self.connection = connection
        self.queue = queue
        self.connectionId = UUID()
        
        if let endpoint = connection.currentPath?.remoteEndpoint {
            switch endpoint {
            case .hostPort(let host, _):
                self.remoteAddress = "\(host)"
            default:
                self.remoteAddress = "unknown"
            }
        } else {
            self.remoteAddress = "unknown"
        }
        
        setupConnection()
    }
    
    private func setupConnection() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            self.queue.async {
                switch state {
                case .ready:
                    self.state = .connected
                    self.delegate?.connection(self, didChangeState: .connected)
                    self.startReceiving()
                    self.startHeartbeat()
                case .waiting(let error):
                    self.delegate?.connection(self, didEncounterError: error)
                case .failed(let error):
                    self.state = .disconnected
                    self.delegate?.connection(self, didChangeState: .disconnected)
                    self.delegate?.connection(self, didEncounterError: error)
                case .cancelled:
                    self.state = .disconnected
                    self.delegate?.connection(self, didChangeState: .disconnected)
                default:
                    break
                }
            }
        }
    }
    
    public func start() {
        state = .connecting
        delegate?.connection(self, didChangeState: .connecting)
        connection.start(queue: queue)
    }
    
    public func send(frame: ProtocolFrame) throws {
        guard state == .connected else {
            throw ProtocolError.connectionError("Connection not ready")
        }
        
        let data = try ProtocolCodec.encode(frame)
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                self.delegate?.connection(self, didEncounterError: error)
            }
        })
    }
    
    private func startReceiving() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                self.delegate?.connection(self, didEncounterError: error)
                return
            }
            
            if let data = data, !data.isEmpty {
                self.receiveBuffer.append(data)
                self.processBuffer()
            }
            
            if !isComplete {
                self.startReceiving()
            }
        }
    }
    
    private func processBuffer() {
        while true {
            // Need at least header size to determine frame size
            guard receiveBuffer.count >= 25 else { break }
            
            // Read payload size from header (offset 17-24)
            let payloadSizeData = receiveBuffer.subdata(in: 17..<25)
            let payloadSize = payloadSizeData.withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
            let totalFrameSize = 25 + Int(payloadSize)
            
            guard receiveBuffer.count >= totalFrameSize else { break }
            
            let frameData = receiveBuffer.subdata(in: 0..<totalFrameSize)
            receiveBuffer.removeFirst(totalFrameSize)
            
            do {
                let frame = try ProtocolCodec.decode(frameData)
                delegate?.connection(self, didReceiveFrame: frame)
            } catch {
                delegate?.connection(self, didEncounterError: error)
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer = DispatchSource.makeTimerSource(queue: queue)
        heartbeatTimer?.schedule(deadline: .now(), repeating: .seconds(30))
        heartbeatTimer?.setEventHandler { [weak self] in
            guard let self = self, self.state == .connected else { return }
            let heartbeatFrame = ProtocolFrame(
                type: .heartbeat,
                payload: Data(),
                sequenceNumber: self.nextSequenceNumber()
            )
            try? self.send(frame: heartbeatFrame)
        }
        heartbeatTimer?.resume()
    }
    
    private func nextSequenceNumber() -> UInt64 {
        sequenceNumber += 1
        return sequenceNumber
    }
    
    public func disconnect() {
        state = .disconnecting
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
        connection.cancel()
        state = .disconnected
        delegate?.connection(self, didChangeState: .disconnected)
    }
}

