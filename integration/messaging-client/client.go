package messaging

import (
	"bufio"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"net"
	"sync"
	"time"
)

// Client represents a messaging engine client
type Client struct {
	conn         net.Conn
	host         string
	port         int
	sequenceNum  uint64
	sequenceLock sync.Mutex
	connected    bool
	connLock     sync.RWMutex
	receiveBuffer []byte
}

// NewClient creates a new messaging client
func NewClient(host string, port int) *Client {
	return &Client{
		host:          host,
		port:          port,
		receiveBuffer: make([]byte, 0, 4096),
	}
}

// Connect connects to the messaging server
func (c *Client) Connect() error {
	address := fmt.Sprintf("%s:%d", c.host, c.port)
	conn, err := net.DialTimeout("tcp", address, 5*time.Second)
	if err != nil {
		return fmt.Errorf("failed to connect: %w", err)
	}
	
	c.connLock.Lock()
	c.conn = conn
	c.connected = true
	c.connLock.Unlock()
	
	// Start receiving messages
	go c.receiveLoop()
	
	// Start heartbeat
	go c.heartbeatLoop()
	
	return nil
}

// Disconnect disconnects from the server
func (c *Client) Disconnect() error {
	c.connLock.Lock()
	defer c.connLock.Unlock()
	
	if !c.connected || c.conn == nil {
		return nil
	}
	
	c.connected = false
	return c.conn.Close()
}

// Send sends a message envelope
func (c *Client) Send(envelope MessageEnvelope) error {
	c.connLock.RLock()
	if !c.connected || c.conn == nil {
		c.connLock.RUnlock()
		return fmt.Errorf("not connected")
	}
	conn := c.conn
	c.connLock.RUnlock()
	
	c.sequenceLock.Lock()
	sequenceNum := c.sequenceNum
	c.sequenceNum++
	c.sequenceLock.Unlock()
	
	frame, err := envelope.ToFrame(sequenceNum)
	if err != nil {
		return fmt.Errorf("failed to create frame: %w", err)
	}
	
	data, err := EncodeFrame(frame)
	if err != nil {
		return fmt.Errorf("failed to encode frame: %w", err)
	}
	
	_, err = conn.Write(data)
	if err != nil {
		return fmt.Errorf("failed to write: %w", err)
	}
	
	return nil
}

// receiveLoop continuously receives frames from the server
func (c *Client) receiveLoop() {
	reader := bufio.NewReader(c.conn)
	buffer := make([]byte, 4096)
	
	for {
		c.connLock.RLock()
		if !c.connected {
			c.connLock.RUnlock()
			return
		}
		c.connLock.RUnlock()
		
		n, err := reader.Read(buffer)
		if err != nil {
			if err == io.EOF {
				return
			}
			fmt.Printf("Read error: %v\n", err)
			return
		}
		
		c.receiveBuffer = append(c.receiveBuffer, buffer[:n]...)
		c.processBuffer()
	}
}

// processBuffer processes received data and extracts frames
func (c *Client) processBuffer() {
	const headerSize = 25
	
	for len(c.receiveBuffer) >= headerSize {
		// Read payload size from header (offset 17-24)
		payloadSize := binary.BigEndian.Uint64(c.receiveBuffer[17:25])
		totalFrameSize := headerSize + int(payloadSize)
		
		if len(c.receiveBuffer) < totalFrameSize {
			// Not enough data yet
			return
		}
		
		frameData := make([]byte, totalFrameSize)
		copy(frameData, c.receiveBuffer[:totalFrameSize])
		c.receiveBuffer = c.receiveBuffer[totalFrameSize:]
		
		frame, err := DecodeFrame(frameData)
		if err != nil {
			fmt.Printf("Failed to decode frame: %v\n", err)
			continue
		}
		
		c.handleFrame(frame)
	}
}

// handleFrame handles a received frame
func (c *Client) handleFrame(frame ProtocolFrame) {
	switch frame.Type {
	case FrameTypeAck:
		var ack MessageAck
		if err := json.Unmarshal(frame.Payload, &ack); err == nil {
			fmt.Printf("Received ACK: %s - %s\n", ack.MessageID, ack.Status)
		}
	case FrameTypeMessage:
		var envelope MessageEnvelope
		if err := json.Unmarshal(frame.Payload, &envelope); err == nil {
			fmt.Printf("Received message: %s\n", string(envelope.Message.Payload))
		}
	case FrameTypeHeartbeat:
		// Echo heartbeat
		heartbeatFrame := ProtocolFrame{
			Type:          FrameTypeHeartbeat,
			Payload:       []byte{},
			SequenceNumber: frame.SequenceNumber,
			Timestamp:     time.Now(),
		}
		if data, err := EncodeFrame(heartbeatFrame); err == nil {
			c.connLock.RLock()
			if c.connected && c.conn != nil {
				c.conn.Write(data)
			}
			c.connLock.RUnlock()
		}
	}
}

// heartbeatLoop sends periodic heartbeats
func (c *Client) heartbeatLoop() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	
	for {
		select {
		case <-ticker.C:
			c.connLock.RLock()
			if !c.connected {
				c.connLock.RUnlock()
				return
			}
			c.connLock.RUnlock()
			
			c.sequenceLock.Lock()
			sequenceNum := c.sequenceNum
			c.sequenceNum++
			c.sequenceLock.Unlock()
			
			heartbeatFrame := ProtocolFrame{
				Type:          FrameTypeHeartbeat,
				Payload:       []byte{},
				SequenceNumber: sequenceNum,
				Timestamp:     time.Now(),
			}
			
			if data, err := EncodeFrame(heartbeatFrame); err == nil {
				c.connLock.RLock()
				if c.connected && c.conn != nil {
					c.conn.Write(data)
				}
				c.connLock.RUnlock()
			}
		}
	}
}

