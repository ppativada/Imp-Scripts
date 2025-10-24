import hashlib
import subprocess

def create_user_credentials(user_id):
    username = user_id
    md5_hash = hashlib.md5(username.encode()).hexdigest()
    password = md5_hash[:8]
    return {"username": username, "password": password}

def create_user_account(username, password):
    try:
        subprocess.run(["sudo", "adduser", "--gecos", "", "--disabled-password", username], check=True)
        command = f"echo '{username}:{password}' | sudo chpasswd"
        subprocess.run(command, shell=True, check=True)
        print(f"User '{username}' created successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to create '{username}': {e}")

def process_user_ids(file_path):
    try:
        with open(file_path, "r") as file:
            user_ids = file.readlines()
        for user_id in user_ids:
            user_id = user_id.strip()
            if user_id:
                credentials = create_user_credentials(user_id)
                create_user_account(credentials["username"], credentials["password"])
    except FileNotFoundError:
        print(f"Error: file not found")
    except Exception as e:
        print(f"an unexpected error: {e}")
    
if __name__ == "__main__":
    file_path = "file path to be added"
    process_user_ids(file_path)
