package checks

import (
	"net"
)

func NetCheck() (passed bool) {
	conn, err := net.Dial("tcp", "go.dev:http")
	if err != nil {
		return false
	}

	defer conn.Close()
	return true
}
