import Foundation

/// Priority queue for message handling (similar to APNs priority handling)
public class MessageQueue {
    private let queue: DispatchQueue
    private var queues: [StandardMessage.MessagePriority: [MessageEnvelope]] = [:]
    private var processingQueues: [StandardMessage.MessagePriority: DispatchQueue] = [:]
    private let lock = NSLock()
    private var isProcessing = false
    
    public var onMessage: ((MessageEnvelope) -> Void)?
    
    public init(queue: DispatchQueue = DispatchQueue(label: "com.messaging.queue", attributes: .concurrent)) {
        self.queue = queue
        
        // Create dedicated processing queues for each priority level
        for priority in [StandardMessage.MessagePriority.critical, .high, .normal, .low] {
            queues[priority] = []
            processingQueues[priority] = DispatchQueue(
                label: "com.messaging.queue.\(priority)",
                qos: qosForPriority(priority)
            )
        }
    }
    
    private func qosForPriority(_ priority: StandardMessage.MessagePriority) -> DispatchQoS {
        switch priority {
        case .critical: return .userInteractive
        case .high: return .userInitiated
        case .normal: return .default
        case .low: return .utility
        }
    }
    
    /// Enqueue a message with priority handling
    public func enqueue(_ envelope: MessageEnvelope) {
        lock.lock()
        defer { lock.unlock() }
        
        let priority = envelope.message.priority
        queues[priority]?.append(envelope)
        
        // Process immediately if not already processing
        if !isProcessing {
            isProcessing = true
            processNext()
        }
    }
    
    private func processNext() {
        // Process in priority order: critical -> high -> normal -> low
        let priorities: [StandardMessage.MessagePriority] = [.critical, .high, .normal, .low]
        
        for priority in priorities {
            lock.lock()
            let hasMessage = !(queues[priority]?.isEmpty ?? true)
            lock.unlock()
            
            if hasMessage {
                processingQueues[priority]?.async { [weak self] in
                    self?.processPriority(priority)
                }
                return
            }
        }
        
        // No messages left
        lock.lock()
        isProcessing = false
        lock.unlock()
    }
    
    private func processPriority(_ priority: StandardMessage.MessagePriority) {
        lock.lock()
        guard let message = queues[priority]?.removeFirst() else {
            lock.unlock()
            processNext()
            return
        }
        lock.unlock()
        
        // Process message
        onMessage?(message)
        
        // Continue processing
        processNext()
    }
    
    public func count() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return queues.values.reduce(0) { $0 + $1.count }
    }
}

/// Message stream for asynchronous event handling
public class MessageStream {
    private let queue: DispatchQueue
    private var subscribers: [String: (MessageEnvelope) -> Void] = [:]
    private let lock = NSLock()
    
    public init(queue: DispatchQueue = DispatchQueue(label: "com.messaging.stream", attributes: .concurrent)) {
        self.queue = queue
    }
    
    /// Subscribe to messages with a topic filter
    public func subscribe(topic: String? = nil, handler: @escaping (MessageEnvelope) -> Void) -> String {
        let subscriptionId = UUID().uuidString
        lock.lock()
        subscribers[subscriptionId] = { envelope in
            if let topic = topic {
                if envelope.message.topic == topic {
                    handler(envelope)
                }
            } else {
                handler(envelope)
            }
        }
        lock.unlock()
        return subscriptionId
    }
    
    /// Unsubscribe from messages
    public func unsubscribe(_ subscriptionId: String) {
        lock.lock()
        subscribers.removeValue(forKey: subscriptionId)
        lock.unlock()
    }
    
    /// Publish a message to all subscribers
    public func publish(_ envelope: MessageEnvelope) {
        lock.lock()
        let handlers = subscribers.values
        lock.unlock()
        
        queue.async {
            for handler in handlers {
                handler(envelope)
            }
        }
    }
}

