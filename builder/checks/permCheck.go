package checks

import (
	"log"
	"syscall"
)


func PrivelageCheck() (passed bool) {
	if syscall.Getuid() != 0{
		log.Fatal("Command must be run as Root")
		return false
	}
	return true

}
