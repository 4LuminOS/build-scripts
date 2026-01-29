package checks

import (
	"log"
	"syscall"
)

// PrivelageCheck checks the UID if the user running isn't root it returns a fatal error!
// should be checked before everything for efficiency
//
// PENDING CONCURRENCY IMPLEMENTATION
func PrivelageCheck() (passed bool) {
	if syscall.Getuid() != 0{ // 0 is the root User ID
		log.Fatal("Command must be run as Root")
		return false
	}
	return true

}
