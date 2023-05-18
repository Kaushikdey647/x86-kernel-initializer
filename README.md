# try-os

How would you know if you don't `try`?

## DESCRIPTION

Guidance credits goes to [CodePulse](https://www.youtube.com/c/CodePulse). This is a 'from-scratch' xv6 bootloader that basically does 3 things:
- Checks cpuid for cpu architecture.
- Checks long mode
- Boots the system
- Initializes page table
- Enables paging
- Allocates stack
- Prints a few characters onto the screen

## INSTALL AND USE

### Prerequisites

- Have docker installed
- Have QEMU installed
- A decent IDE for development please

### Enter the docker env

- Build the docker image using `sudo docker build buildenv -t try-os` (first time only)
- Enter the environment using
    - Linux/Unix/Mac: `sudo docker run --rm -it -v $(pwd):/root/env try-os`
    - Make the ISO File: `make build-x86_64`
- After Exiting the environment
    - Boot into qemu: `qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso`
