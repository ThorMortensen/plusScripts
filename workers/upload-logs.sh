#!/bin/bash

if [ -z "$1" ]; then
  echo "Please provide device ID"
  exit 1
fi

echo "Uploading logs for device $1"
echo "(It may take up to 15 min for the log upload to start on the device and the upload may take a long time depending on the log size)"

token=$(gcloud auth print-identity-token)
user_name=$(gcloud config get-value account)
base_name=$(echo "$user_name" | cut -d'@' -f1)
bucket_folder="$base_name/release-test-$(date +'%Y-%m-%d')-$1"
accel_dist="$bucket_folder/accel"
can_dist="$bucket_folder/can"
journald_dist="$bucket_folder/journald"
state_dist="$bucket_folder/state"

convert_google_token_to_jwt() {
  local google_token=$1
  local api_url="https://auth-api.connectedcars.io/auth/login/googleConverter"
  local jwt_token

  jwt_token=$(curl -s -X POST "$api_url" \
    -H "X-Organization-Namespace: cctech:workshop" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"token\": \"$google_token\"}" | jq -r '.token')

  if [ -z "$jwt_token" ] || [ "$jwt_token" == "null" ]; then
    echo "Error: Failed to convert Google token to JWT token"
    return 1
  fi

  echo "$jwt_token"
  return 0
}

echo "Creating bucket for logs..."

get_bucket_url() {
  response=$(curl -s -i -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      "https://storage.googleapis.com/upload/storage/v1/b/device-debugging-logs/o?uploadType=resumable&name=$1")
  location=$(echo "$response" | grep -i "location:" | awk '{print $2}' | tr -d '\r')
  echo "$location"
}
accel_url=$(get_bucket_url "$accel_dist")
can_url=$(get_bucket_url "$can_dist")
journald_url=$(get_bucket_url "$journald_dist")
state_url=$(get_bucket_url "$state_dist")
one_hour_from_now=$(date -u -d '1 hour' +'%Y-%m-%dT%H:%M:%S.000Z')

echo "Assembling GraphQL command..."

log_cmd=$(cat <<EOF
  "{\"logs\": [
    {
      \"upload_url\": \"$accel_url\",
      \"compress\": false,
      \"log_type\": \"Accel\"
    },
    {
      \"upload_url\": \"$can_url\",
      \"compress\": false,
      \"log_type\": \"Can\"
    },
    {
      \"upload_url\": \"$journald_url\",
      \"compress\": true,
      \"log_type\": \"Journal\"
    },
    {
      \"upload_url\": \"$state_url\",
      \"compress\": true,
      \"log_type\": \"State\"
    }
  ]}"
EOF
)

log_cmd_clean=$(echo "$log_cmd" | tr -d '\n' | tr -s ' ')

debug_cmd=$(cat <<EOF
mutation addDebugCommands {
  addUnitDebugCommand(input: {
    data: $log_cmd_clean,
    unitId: "$1",
    validUntil: "$one_hour_from_now"
  })
}
EOF
)

echo "Fetching tokens..."

# Define the GraphQL endpoint
GRAPHQL_ENDPOINT="https://api.connectedcars.io/graphql"
payload=$(jq -n --arg query "$debug_cmd" '{ query: $query }')
jwt_token=$(convert_google_token_to_jwt "$token")

echo "Sending upload command..."

# Send the request and capture the response
response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "X-Organization-Namespace: cctech:workshop" \
  -H "Authorization: Bearer $jwt_token" \
  -d "$payload" \
  "$GRAPHQL_ENDPOINT")

# Check if the response contains success
if echo "$response" | grep -q '"addUnitDebugCommand":true'; then
  echo -e "\033[1;32mLog-upload command sent successfully. Find them here:\033[0m"
  dist_link="https://console.cloud.google.com/storage/browser/device-debugging-logs/$bucket_folder?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&authuser=2&inv=1&invt=AbmZ4Q&project=connectedcars-147810"
  echo -e "\033[4;34m$dist_link\033[0m"
else
  echo -e "\033[1;31mFailed to send log-upload command.\033[0m"
  echo "Response: $response"
  exit 1
fi