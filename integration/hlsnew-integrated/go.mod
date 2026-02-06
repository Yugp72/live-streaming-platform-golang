module hlsnew-integrated

go 1.21

require (
	messaging-client v0.0.0
	streaming-events v0.0.0
)

replace messaging-client => ../messaging-client

replace streaming-events => ../streaming-events
