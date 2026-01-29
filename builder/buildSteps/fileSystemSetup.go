package buildsteps

import (
	"log"
	"os"
	"fmt"
	"path/filepath"
)

func FileSystemSetup(){
	const baseDirectory = "../LuminOS-build"
	_, err := os.Stat(baseDirectory)
	// Check if the base directory exists. If it does, yoink it (safely).
	if !os.IsNotExist(err) {
		fmt.Println("WARNING: Base build directory already exists, it will be deleted.")
		fmt.Print("Proceed? [y/n] ")
		var proceed string 
		fmt.Scanln(&proceed)
		switch  proceed {
		case "y":
			err := os.RemoveAll(baseDirectory)
			if err != nil {
				log.Fatalf("Failed to remove existant base directory: %v", err)
			}
		default:
			fmt.Println("Aborted.")
			os.Exit(0)
		}
	}
	err = os.Mkdir(baseDirectory, os.FileMode(os.O_CREATE))
	if err != nil {
		log.Fatalf("Failed to created base directory: %v", err)
	}
	// Create build subdirectories.
	workDirectory := filepath.Join(baseDirectory, "work")
	chrootDirectory := filepath.Join(baseDirectory, "chroot")
	isoDirectory := filepath.Join(baseDirectory, "iso")
	aiBuildDirectory := filepath.Join(baseDirectory, "ai_build")
	if err := os.Mkdir(workDirectory, os.FileMode(os.O_RDWR)) ; err != nil {
		log.Fatalf("Failed creating work directory: %v", err)
	}
	if err := os.Mkdir(chrootDirectory, os.FileMode(os.O_RDWR)) ; err != nil {
		log.Fatalf("Failed creating chroot directory: %v", err)
	}
	if err := os.Mkdir(isoDirectory, os.FileMode(os.O_RDWR)) ; err != nil {
		log.Fatalf("Failed creating ISO directory: %v", err)
	}
	if err := os.Mkdir(aiBuildDirectory, os.FileMode(os.O_RDWR)) ; err != nil {
		log.Fatalf("Failed creating AI build directory: %v", err)
	}
}