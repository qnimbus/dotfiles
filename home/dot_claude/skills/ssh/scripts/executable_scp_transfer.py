#!/usr/bin/env python3
"""
SCP File Transfer Script

Transfer files to/from remote hosts using SCP with secure credential handling.
Supports recursive directory transfers and uses the same authentication methods
as ssh_exec.py.

Usage:
    # Upload file to remote
    python3 scp_transfer.py upload local_file.txt /remote/path/file.txt

    # Download file from remote
    python3 scp_transfer.py download /remote/path/file.txt local_file.txt

    # Upload directory recursively
    python3 scp_transfer.py upload local_dir/ /remote/path/dir/ --recursive

    # Using connection parameters
    python3 scp_transfer.py upload app.py /opt/app/app.py --host example.com --user deploy

Environment Variables:
    SSH_HOST: Remote hostname or IP
    SSH_USER: SSH username
    SSH_PORT: SSH port (default: 22)
    SSH_KEY_PATH: Path to private key file
    SSH_PASSWORD: Password for authentication
"""

import argparse
import os
import sys
import subprocess
from pathlib import Path


def get_connection_params():
    """Extract connection parameters from environment variables."""
    return {
        'host': os.getenv('SSH_HOST'),
        'user': os.getenv('SSH_USER'),
        'port': os.getenv('SSH_PORT', '22'),
        'key_path': os.getenv('SSH_KEY_PATH'),
        'password': os.getenv('SSH_PASSWORD'),
    }


def build_scp_command(source, destination, host, user, port='22', key_path=None,
                      password=None, recursive=False):
    """
    Build SCP command with appropriate authentication.

    SECURITY: Like ssh_exec.py, this function NEVER reads private keys.
    It only passes paths to the scp command.
    """
    scp_cmd = ['scp']

    # Add port if not default
    if port and port != '22':
        scp_cmd.extend(['-P', str(port)])

    # Add key file path if provided
    if key_path:
        key_file = Path(key_path).expanduser()
        if not key_file.exists():
            print(f"Warning: Key file not found: {key_file}", file=sys.stderr)
        scp_cmd.extend(['-i', str(key_file)])

    # Recursive flag
    if recursive:
        scp_cmd.append('-r')

    # Disable strict host key checking
    scp_cmd.extend(['-o', 'StrictHostKeyChecking=accept-new'])

    # Add source and destination
    scp_cmd.extend([source, destination])

    return scp_cmd, password


def transfer_file(operation, local_path, remote_path, host, user, port='22',
                  key_path=None, password=None, recursive=False):
    """
    Transfer files using SCP.

    Args:
        operation: 'upload' or 'download'
        local_path: Local file/directory path
        remote_path: Remote file/directory path
        host: Remote hostname
        user: SSH username
        port: SSH port
        key_path: Path to private key
        password: SSH password
        recursive: Enable recursive transfer

    Returns:
        dict with success status and messages
    """
    # Build source and destination based on operation
    if operation == 'upload':
        source = local_path
        destination = f"{user}@{host}:{remote_path}"

        # Check if local path exists
        if not Path(local_path).exists():
            return {
                'success': False,
                'error': f"Local path not found: {local_path}"
            }
    else:  # download
        source = f"{user}@{host}:{remote_path}"
        destination = local_path

    scp_cmd, pwd = build_scp_command(
        source, destination, host, user, port, key_path, password, recursive
    )

    # If password provided, use sshpass
    if pwd:
        if subprocess.run(['which', 'sshpass'], capture_output=True).returncode != 0:
            return {
                'success': False,
                'error': 'Password authentication requires sshpass to be installed'
            }
        scp_cmd = ['sshpass', '-e'] + scp_cmd
        env = os.environ.copy()
        env['SSHPASS'] = pwd
    else:
        env = None

    try:
        result = subprocess.run(
            scp_cmd,
            capture_output=True,
            text=True,
            env=env
        )

        if result.returncode == 0:
            return {
                'success': True,
                'message': f"Successfully {operation}ed: {local_path} {'to' if operation == 'upload' else 'from'} {remote_path}"
            }
        else:
            return {
                'success': False,
                'error': result.stderr or f"Transfer failed with exit code {result.returncode}"
            }

    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }


def main():
    parser = argparse.ArgumentParser(
        description='Transfer files to/from remote hosts via SCP',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument('operation', choices=['upload', 'download'],
                        help='Transfer direction')
    parser.add_argument('source', help='Source file/directory path')
    parser.add_argument('destination', help='Destination file/directory path')
    parser.add_argument('--host', help='Remote hostname (default: SSH_HOST env var)')
    parser.add_argument('--user', help='SSH username (default: SSH_USER env var)')
    parser.add_argument('--port', help='SSH port (default: SSH_PORT env var or 22)')
    parser.add_argument('--key-path', help='Path to SSH private key (default: SSH_KEY_PATH env var)')
    parser.add_argument('--password', help='SSH password (default: SSH_PASSWORD env var)')
    parser.add_argument('-r', '--recursive', action='store_true',
                        help='Recursively copy directories')

    args = parser.parse_args()

    # Get connection parameters
    env_params = get_connection_params()

    host = args.host or env_params['host']
    user = args.user or env_params['user']
    port = args.port or env_params['port']
    key_path = args.key_path or env_params['key_path']
    password = args.password or env_params['password']

    # Validate required parameters
    if not host or not user:
        print("Error: SSH_HOST and SSH_USER must be provided", file=sys.stderr)
        sys.exit(1)

    # Perform transfer
    result = transfer_file(
        operation=args.operation,
        local_path=args.source,
        remote_path=args.destination,
        host=host,
        user=user,
        port=port,
        key_path=key_path,
        password=password,
        recursive=args.recursive
    )

    if result['success']:
        print(result['message'])
    else:
        print(f"Error: {result['error']}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
