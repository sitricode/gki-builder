#!/usr/bin/env bash

# ------------------
# Functions
# ------------------

# Telegram functions

# upload_file <path/to/file>
upload_file() {
  local FILE="$1"
  if ! [[ -f $FILE ]]; then
    error "file $FILE doesn't exist"
  fi
  chmod 777 $FILE
  curl -s -F document=@"$FILE" "https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument" \
    -F "chat_id=$CHAT_ID" \
    -F "disable_web_page_preview=true" \
    -F "parse_mode=markdown"
}

# reply_file <message_id> <path/to/file>
reply_file() {
  local MESSAGE_ID="$1"
  local FILE="$2"
  if ! [[ -f $FILE ]]; then
    error "file $FILE doesn't exist"
  fi
  chmod 777 $FILE
  curl -s -F document=@"$FILE" "https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument" \
    -F "chat_id=$CHAT_ID" \
    -F "reply_to_message_id=$MESSAGE_ID" \
    -F "disable_web_page_preview=true" \
    -F "parse_mode=markdown"
}

upload_file() {
    local file="$1"

    if ! [[ -f $file ]]; then
        error "file $file doesn't exist"
    fi

    chmod 777 $file

    curl -s -F document=@"$file" "https://api.telegram.org/bot$TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=markdown" \
        -o /dev/null
}

send_msg() {
    local msg="$1"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="$msg" \
}
# reply_msg <text>
reply_msg() {
  local MESSAGE_ID="$1"
  local MESSAGE="$2"
  curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
    -d "chat_id=$CHAT_ID" \
    -d "reply_to_message_id=$MESSAGE_ID" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=markdown" \
    -d "text=$MESSAGE"
}
# KernelSU installation function
install_ksu() {
    local repo="$1"
    local ref="$2" # Can be a branch or a tag

    [[ -z $repo ]] && {
        echo "Usage: install_ksu <repo-username/ksu-repo-name> [branch-or-tag]"
        return 1
    }

    # Fetch the latest tag (always needed for KSU_VERSION)
    local latest_tag=$(gh api repos/$repo/tags --jq '.[0].name')

    # Determine whether the reference is a branch or tag
    local ref_type="tags" # Default to tag
    if [[ -n $ref ]]; then
        # Check if the provided ref is a branch
        if gh api repos/$repo/branches --jq '.[].name' | grep -q "^$ref$"; then
            ref_type="heads"
        fi
    else
        ref="$latest_tag" # Default to latest tag
    fi

    # Construct the correct raw GitHub URL
    local url="https://raw.githubusercontent.com/$repo/refs/$ref_type/$ref/kernel/setup.sh"

    log "Installing KernelSU from $repo ($ref)..."
    curl -LSs "$url" | bash -s "$ref"

    # Always set KSU_VERSION to the latest tag
    KSU_VERSION="$latest_tag"
}

# Kernel scripts function
config() {
    $workdir/common/scripts/config "$@"
}

# Logging function
log() {
    echo -e "\033[32m[LOG]\033[0m $*"
}

error() {
    echo -e "\033[31m[ERROR]\033[0m $*"
    upload_file "$workdir/build.log"
    exit 1
}
