package checks

import (
	"bytes"
	"fmt"
	"log"
	"os/exec"
)

// OsCheck PENDING CONCURRENCY IMPLEMENTATION
func OsCheck() (passed bool, err error) {

	// cmd sends this command to the OS shell
	cmd := exec.Command("cat", "/etc/os-release")

	// we connect to standard output using cmd.StdoutPipe function
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	// Start Executing the Commmand, does not wait for commmand by defualt
	if err = cmd.Start(); err != nil {
		log.Fatal(err)
	}

	out := make([]byte, 400)

	// Read from standard output, We will read the entire /etc/os-release file
	_, err = stdout.Read(out)
	if err != nil {
		log.Fatal(err)
	}
	// This waits until the above function finishes
	if err = cmd.Wait(); err != nil {
		log.Fatal(err)
	}

	/*
		We could Refactor this to use the PRETTY NAME field,
		but I am unsure if that value can be changed when changing hostname (pending test), will re-implement based on results
		until then, we Will use the Distro code name to ensure a reliable answer

		This version is more reliable and preferred, so I'll keep it until any problems arise
	*/

	switch {
	case bytes.Contains(out, []byte("Noble Numbat")): // Ubuntu 24.04 LTS
		return true, nil
	case bytes.Contains(out, []byte("Trixie")): // Debian 13
		return true, nil
	case bytes.Contains(out, []byte("Bookworm")): // Debian 12
		return true, nil
	default:
		return false, fmt.Errorf("builder cannot run on this operating system") // Neither of the Above

	}
}
