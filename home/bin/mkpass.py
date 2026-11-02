import scramp
import base64
import getpass
import sys

password = getpass.getpass("Enter password for PostgreSQL user: ")

confirm = getpass.getpass("Confirm password: ")
if password != confirm:
    print("Error: passwords do not match", file=sys.stderr)
    sys.exit(1)

m = scramp.ScramMechanism()
salt, stored_key, server_key, iteration_count = m.make_auth_info(password)

print(f"SCRAM-SHA-256${iteration_count}:{base64.b64encode(salt).decode()}${base64.b64encode(stored_key).decode()}:{base64.b64encode(server_key).decode()}")
