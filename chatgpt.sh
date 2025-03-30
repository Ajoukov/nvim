#!/bin/bash
set -euo pipefail

# GLOBIGNORE="*"

CHATGPT_CYAN_LABEL="\033[36mchatgpt \033[0m"
PROCESSING_LABEL="\n\033[90mProcessing... \033[0m\033[0K\r"
OVERWRITE_PROCESSING_LINE="             \033[0K\r"
SYSTEM_PROMPT="Answer as concisely as possible. Current date: $(date +%m/%d/%Y). Knowledge cutoff: 9/1/2021."
OPENAI_KEY="key"
MODEL="gpt-4o-mini-2024-07-18"
# MODEL="gpt-3.5-turbo"
TEMPERATURE="0.7"
MAX_TOKENS="1024"
SIZE="512x512"

CONVERSATION_DIR="$HOME/.chatgpt_conversations"
mkdir -p "$CONVERSATION_DIR"
CURRENT_CONVERSATION_FILE="$HOME/.chatgpt_current_conversation"

if [[ "${1:-}" == "-w" ]]; then
    rm -f "$CONVERSATION_DIR/$2" || echo "Failed to delete"
    echo "Conversation $2 wiped."
    exit 0
elif [[ "${1:-}" == "-W" ]]; then
    rm -f "$CONVERSATION_DIR/"* || echo "Failed to delete"
    echo rm -f "$CONVERSATION_DIR/"*
    echo "All conversations wiped."
    exit 0
fi

if [[ "${1:-}" =~ ^-[0-9]+$ ]]; then
    CONVERSATION_ID="${1#-}"
    echo "$CONVERSATION_ID" > "$CURRENT_CONVERSATION_FILE"
    shift
elif [ -z "${CONVERSATION_ID:-}" ] && [ -f "$CURRENT_CONVERSATION_FILE" ]; then
    CONVERSATION_ID=$(cat "$CURRENT_CONVERSATION_FILE")
fi

if [ -n "${CONVERSATION_ID:-}" ]; then
    CONVERSATION_FILE="$CONVERSATION_DIR/$CONVERSATION_ID"
else
    CONVERSATION_FILE=""
fi

if [ -n "$CONVERSATION_FILE" ] && [ -f "$CONVERSATION_FILE" ]; then
    history_text=$(cat "$CONVERSATION_FILE")
else
    history_text=""
fi

# Process additional parameters.
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -M)
	    MODEL="gpt-4.5-preview-2025-02-27"
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [ ! -t 0 ]; then
    stdin_text=$(cat -)
    if [ "$#" -gt 0 ]; then
         prompt="${stdin_text}\n$*"
    else
         prompt="${stdin_text}"
    fi
else
    if [ "$#" -gt 0 ]; then
         prompt="$*"
    else
         read -e -p "Welcome to chatgpt. Type your prompt: " prompt
    fi
fi

[ -z "$prompt" ] && { echo "No prompt provided."; exit 0; }

system_message="$SYSTEM_PROMPT"
if [ -n "$history_text" ]; then
    system_message="$system_message\nConversation History:\n$history_text"
fi
payload=$(jq -n \
    --arg model "$MODEL" \
    --arg max_tokens "$MAX_TOKENS" \
    --arg temperature "$TEMPERATURE" \
    --arg system "$system_message" \
    --arg user "$prompt" \
    '{
       model: $model,
       messages: [
           {role: "system", content: $system},
           {role: "user", content: $user}
       ],
       max_tokens: ($max_tokens | tonumber),
       temperature: ($temperature | tonumber)
    }')

echo $payload > $CONVERSATION_DIR/.chatgpt_payload
echo $CONVERSATION_DIR/.chatgpt_payload

response=$(curl https://api.openai.com/v1/chat/completions \
    -sS \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $OPENAI_KEY" \
    -d "$payload")

if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
    echo "$response" | jq .
    exit 1
fi

response_text=$(echo "$response" | jq -r '.choices[].message.content')
echo -e "${CHATGPT_CYAN_LABEL}$(echo "$response_text" | fold -s -w 60)"

# response_text=$(echo "$response" | jq -r '.choices[].message.content')
# echo -e "${CHATGPT_CYAN_LABEL}$response_text"

timestamp=$(date +"%Y-%m-%d %H:%M")
if [ -n "$CONVERSATION_FILE" ]; then
    {
        echo -e "$timestamp user: $prompt"
        echo -e "$timestamp chatgpt: $response_text\n"
    } >> "$CONVERSATION_FILE"
fi

