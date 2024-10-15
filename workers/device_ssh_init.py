import pexpect
import itertools
import sys
import time
import threading

# ANSI escape codes for colors and styles
BOLD = '\033[1m'
YELLOW = '\033[33m'
GREEN = '\033[32m'
RED = '\033[31m'
RESET = '\033[0m'

# Spinner function to display a spinner while waiting
def spinner(message, stop_event):
    spinner_cycle = itertools.cycle([f'{YELLOW}-', f'{YELLOW}\\', f'{YELLOW}|', f'{YELLOW}/'])
    while not stop_event.is_set():
        sys.stdout.write(f'\r{BOLD}{message} {next(spinner_cycle)}{RESET}')
        sys.stdout.flush()
        time.sleep(0.1)
    sys.stdout.write(f'\r{BOLD}{message} {GREEN}✓{RESET}\n')
    sys.stdout.flush()
    sys.stdout.write('\r')  # Clear the line when done

# Function to initialize and connect via SSH
def initialize_terminal(device, rc_content, stop_event):
    ssh_command = f"auth-wrapper ssh -t -o TCPKeepAlive=no -o ServerAliveInterval=10 -o ServerAliveCountMax=3 support@{device}"
    ssh_session = pexpect.spawn(ssh_command, timeout=35)

    # Wait for the shell prompt
    ssh_session.expect(r'\$ ')

    # Send the contents of the remote.rc file to the remote shell
    for line in rc_content.splitlines():
        time.sleep(0.1)  # Sleep for 0.1 seconds before sending each line
        ssh_session.sendline(line)
        ssh_session.expect(r'\$ ')

    # Stop the spinner once the initialization is done
    stop_event.set()

    ssh_session.sendline("")
    ssh_session.expect(r'\$ ')

    return ssh_session


# Function to handle the SSH session and monitor status
def handle_session(device, rc_content):
    # Create a threading event to control the spinner
    stop_event = threading.Event()

    # Start the spinner in a separate thread
    spinner_thread = threading.Thread(target=spinner, args=("Connecting and initializing terminal", stop_event))
    spinner_thread.start()

    try:
        ssh_session = initialize_terminal(device, rc_content, stop_event)

        # Ensure the spinner thread is joined after the terminal is initialized
        stop_event.set()  # Stop the spinner
        spinner_thread.join()

        if ssh_session is None:
            return 1  # Error occurred, return error code 1 (timeout, connection lost)

        print(f"{GREEN}Terminal ready!{RESET}")

        # Hand over control to the user (open interactive session)
        ssh_session.interact()  # Hand control to the user

        # Check if the session was closed by user (EOF means user closed the session)
        ssh_session.expect(pexpect.EOF)

        # Check for a message indicating the connection was closed by the remote host
        if ssh_session.before and b"closed by remote host" in ssh_session.before:
            print(f"{RED}Connection closed by remote host! Device rebooted.{RESET}")
            return 2  # Return error code 2 to indicate device reboot
        else:
            return 0  # User closed the session, return 0 for normal exit

    except KeyboardInterrupt:
        # Handle Ctrl+C cleanly, stop the spinner, and return the exit code for interruption
        stop_event.set() 
        spinner_thread.join()  
        print(f"\nCanceled. Exiting...")
        return 130  # Return exit code 130 (commonly used for Ctrl+C interrupt)

    except pexpect.exceptions.EOF:
        # Connection lost unexpectedly (not by user)
        stop_event.set() 
        spinner_thread.join()  
        print(f"{RED}Connection lost unexpectedly!{RESET}")
        return 1  # Error code 1 for unexpected closure

    except pexpect.exceptions.TIMEOUT:
        # Connection timed out
        stop_event.set() 
        spinner_thread.join()  
        print(f"{RED}Connection timed out!{RESET}")
        return 1  # Error code 1 for timeout

# Main function to handle the script flow
def main():
    # Check if the arguments are provided
    if len(sys.argv) < 3:
        print("Usage: script.py <path_to_rc_file> <device>")
        sys.exit(1)

    # Get the arguments from the command line
    rc_file_path = sys.argv[1]
    device = sys.argv[2]

    # Read the contents of the rc file provided as arg1
    with open(rc_file_path, "r") as file:
        rc_content = file.read()

    # Handle the SSH session and get the exit code
    exit_code = handle_session(device, rc_content)

    # Exit the script with the proper exit code (0 for success, 1 for errors)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
