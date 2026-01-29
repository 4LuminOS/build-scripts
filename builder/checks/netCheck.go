package checks

import (
	"net"
)

func NetCheck() (passed bool) {
	conn, err := net.DialTimeout("tcp", "go.dev:http", 10)
	if err != nil {
		return false
	}

	defer conn.Close()
	return true
}
