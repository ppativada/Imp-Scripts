#!/usr/bin/env bash
# create_users_from_txt.sh
# Usage:
#   ./create_users_from_txt.sh --file users.txt          # create users
#   ./create_users_from_txt.sh --file users.txt --test   # print only

set -o pipefail

FILE=""
TEST_MODE=0

# --- arg parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file|-f)
      FILE="$2"; shift 2;;
    --test)
      TEST_MODE=1; shift;;
    -h|--help)
      echo "Usage: $0 --file users.txt [--test]"
      exit 0;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 --file users.txt [--test]"
      exit 1;;
  esac
done

if [[ -z "$FILE" ]]; then
  echo "Error: --file is required"
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "Error: file not found: $FILE"
  exit 1
fi

# Ensure required tools exist
if ! command -v md5sum >/dev/null 2>&1; then
  echo "Error: md5sum not found (install coreutils)."
  exit 1
fi

# --- functions ---
md5_8() {
  # prints first 8 hex chars of MD5 hash of stdin
  # usage: printf %s "string" | md5_8
  LC_ALL=C md5sum | awk '{print $1}' | cut -c1-8
}

create_user_account() {
  local username="$1"
  local password="$2"

  # Check if user exists
  if id -u "$username" >/dev/null 2>&1; then
    # user exists; still set (or reset) password
    if echo "${username}:${password}" | sudo chpasswd; then
      echo "[OK] ${username} -> ${password} (password updated)"
      return 0
    else
      echo "[ERR] Failed to set password for '${username}'" >&2
      return 1
    fi
  else
    # create user without interactive prompts, no initial password
    if sudo adduser --gecos "" --disabled-password "$username"; then
      if echo "${username}:${password}" | sudo chpasswd; then
        echo "[OK] ${username} -> ${password} (created)"
        return 0
      else
        echo "[ERR] Created '${username}' but failed to set password" >&2
        return 1
      fi
    else
      echo "[ERR] Failed to create '${username}'" >&2
      return 1
    fi
  fi
}

# --- main ---
while IFS= read -r line || [[ -n "$line" ]]; do
  # trim whitespace
  username="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

  # skip empty or comment lines
  [[ -z "$username" ]] && continue
  [[ "$username" =~ ^# ]] && continue

  # compute password: md5(username) first 8 chars
  password="$(printf %s "$username" | md5_8)"

  if [[ $TEST_MODE -eq 1 ]]; then
    echo "[TEST] ${username} -> ${password}"
  else
    create_user_account "$username" "$password"
  fi
done < "$FILE"
