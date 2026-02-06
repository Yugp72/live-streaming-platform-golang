module demo-client

go 1.21

replace messaging-client => ../messaging-client

replace streaming-events => ../streaming-events

require (
	messaging-client v0.0.0-00010101000000-000000000000
	streaming-events v0.0.0-00010101000000-000000000000
)

