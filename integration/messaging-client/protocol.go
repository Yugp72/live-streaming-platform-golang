package messaging

import (
	"encoding/binary"
	"errors"
	"time"
)

// FrameType represents the type of protocol frame
type FrameType uint8

const (
	FrameTypeMessage    FrameType = 0x01
	FrameTypeAck        FrameType = 0x02
	FrameTypeHeartbeat  FrameType = 0x03
	FrameTypeSubscribe  FrameType = 0x04
	FrameTypeUnsubscribe FrameType = 0x05
	FrameTypeError      FrameType = 0xFF
)

// ProtocolFrame represents a frame in the messaging protocol
type ProtocolFrame struct {
	Type          FrameType
	Payload       []byte
	SequenceNumber uint64
	Timestamp     time.Time
}

// EncodeFrame encodes a ProtocolFrame to binary data
func EncodeFrame(frame ProtocolFrame) ([]byte, error) {
	data := make([]byte, 0, 25+len(frame.Payload))
	
	// Frame type (1 byte)
	data = append(data, byte(frame.Type))
	
	// Sequence number (8 bytes, big endian)
	seqBytes := make([]byte, 8)
	binary.BigEndian.PutUint64(seqBytes, frame.SequenceNumber)
	data = append(data, seqBytes...)
	
	// Timestamp (8 bytes, milliseconds since epoch, big endian)
	timestampMs := uint64(frame.Timestamp.UnixMilli())
	timestampBytes := make([]byte, 8)
	binary.BigEndian.PutUint64(timestampBytes, timestampMs)
	data = append(data, timestampBytes...)
	
	// Payload size (8 bytes, big endian)
	payloadSize := uint64(len(frame.Payload))
	payloadSizeBytes := make([]byte, 8)
	binary.BigEndian.PutUint64(payloadSizeBytes, payloadSize)
	data = append(data, payloadSizeBytes...)
	
	// Payload
	data = append(data, frame.Payload...)
	
	return data, nil
}

// DecodeFrame decodes binary data to a ProtocolFrame
func DecodeFrame(data []byte) (ProtocolFrame, error) {
	const headerSize = 25
	
	if len(data) < headerSize {
		return ProtocolFrame{}, errors.New("frame too short")
	}
	
	var frame ProtocolFrame
	var offset int
	
	// Frame type
	frame.Type = FrameType(data[offset])
	offset++
	
	// Sequence number
	frame.SequenceNumber = binary.BigEndian.Uint64(data[offset : offset+8])
	offset += 8
	
	// Timestamp
	timestampMs := binary.BigEndian.Uint64(data[offset : offset+8])
	frame.Timestamp = time.UnixMilli(int64(timestampMs))
	offset += 8
	
	// Payload size
	payloadSize := binary.BigEndian.Uint64(data[offset : offset+8])
	offset += 8
	
	// Payload
	if len(data) < offset+int(payloadSize) {
		return ProtocolFrame{}, errors.New("payload incomplete")
	}
	frame.Payload = make([]byte, payloadSize)
	copy(frame.Payload, data[offset:offset+int(payloadSize)])
	
	return frame, nil
}

