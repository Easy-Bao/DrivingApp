// Package realtime contains delivery infrastructure shared by live ride and
// chat workflows.
//
// The hub package publishes validated event envelopes to identity topics for
// the realtime stream. Chat transport owns RoomHub separately because chat
// clients use room-scoped raw frames and a different websocket protocol.
package realtime
