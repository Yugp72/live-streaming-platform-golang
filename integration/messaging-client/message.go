package messaging

import (
	"encoding/json"
	"time"
)

// MessagePriority represents message priority levels
type MessagePriority int

const (
	PriorityLow     MessagePriority = 0
	PriorityNormal  MessagePriority = 1
	PriorityHigh    MessagePriority = 2
	PriorityCritical MessagePriority = 3
)

// Message represents a standard message
type Message struct {
	ID        string          `json:"id"`
	Timestamp time.Time       `json:"timestamp"`
	Payload   []byte          `json:"payload"`
	Topic     *string         `json:"topic,omitempty"`
	Priority  MessagePriority `json:"priority"`
}

// MessageEnvelope wraps a message with routing information
type MessageEnvelope struct {
	Message     Message           `json:"message"`
	Source      string            `json:"source"`
	Destination *string           `json:"destination,omitempty"`
	Metadata    map[string]string `json:"metadata"`
}

// MessageAck represents a message acknowledgment
type MessageAck struct {
	MessageID string    `json:"messageId"`
	Status    string    `json:"status"` // "delivered", "failed", "pending"
	Timestamp time.Time `json:"timestamp"`
}

// NewMessage creates a new message
func NewMessage(payload []byte, topic string, priority MessagePriority) Message {
	return Message{
		ID:        generateID(),
		Timestamp: time.Now(),
		Payload:   payload,
		Topic:     &topic,
		Priority:  priority,
	}
}

// NewMessageEnvelope creates a new message envelope
func NewMessageEnvelope(message Message, source string) MessageEnvelope {
	return MessageEnvelope{
		Message:  message,
		Source:   source,
		Metadata: make(map[string]string),
	}
}

// ToFrame converts a MessageEnvelope to a ProtocolFrame
func (e MessageEnvelope) ToFrame(sequenceNumber uint64) (ProtocolFrame, error) {
	payload, err := json.Marshal(e)
	if err != nil {
		return ProtocolFrame{}, err
	}
	
	return ProtocolFrame{
		Type:          FrameTypeMessage,
		Payload:       payload,
		SequenceNumber: sequenceNumber,
		Timestamp:     time.Now(),
	}, nil
}

// generateID generates a simple ID (in production, use UUID)
func generateID() string {
	return time.Now().Format("20060102150405.000000")
}

