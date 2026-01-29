# TO-DOs
- [x] Checks to ensure the system is appropriate for building
        - [x] OS
        - [x] Network
        - [x] Privelage
        - [x] Storage

- [] Create Directories for build
- [] Install Dependencies (Bootstrapping Debian)
- [] Download or Find the AI Models (Gemma3. )
- [] Mount directories and post-install scripts
- [] Build ISO
- [] Concurrent Implementation of all of the above
        Ideally we should implement all of the above linearly (no concurrency!) to make it easier to debug,
        because goroutines are hellish when attempting to debug (true facts), especially when core functionality itself hasn't been added
        Resources for Concurrency because, doing things is hard, doing it concurrently is even harder!
                -> [Concurrency Patterns](https://github.com/lotusirous/go-concurrency-patterns)
                -> [Sync Package Spec (we should really just read the source its way easier!)](https://pkg.go.dev/sync)
                -> 
