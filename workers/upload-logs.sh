#!/bin/bash

# Default option values
USE_PROXY=false
ENABLE_SSH=false
DURATION=6
DEVICE_ID=""
ONLY_ACCEL=false

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -d, --device DEVICE_ID   Specify device ID (mandatory)"
  echo "  -p, --proxy              Use proxy for upload (default: false)"
  echo "  -s, --ssh                Enable SSH (default: false)"
  echo "  -t, --timealive HOURS    Set duration in hours (default: 6)"
  echo "  -a, --accel              Only upload accel"
  echo "  -h, --help               Display this help message"
}

# Parse options
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -d|--device)
      if [[ -n "$2" && "$2" != -* ]]; then
        DEVICE_ID="$2"
        shift 2
      else
        echo "Error: --device requires an argument."
        usage
        exit 1
      fi
      ;;
    -p|--proxy)
      echo "Using proxy for upload"
      USE_PROXY=true
      shift
      ;;
    -s|--ssh)
      echo "Enabling SSH"
      ENABLE_SSH=true
      shift
      ;;
    -a|--accel)
      echo "Only uploading accel logs"
      ONLY_ACCEL=true
      shift
      ;;
    -t|--timealive)
      if [[ -n "$2" && "$2" != -* ]]; then
        echo "Setting time alive to $2 hours"
        DURATION="$2"
        shift 2
      else
        echo "Error: --timealive requires an argument."
        usage
        exit 1
      fi
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z "$DEVICE_ID" ]; then
  echo "Error: device ID is mandatory."
  usage
  exit 1
fi

echo "Uploading logs for device $DEVICE_ID"
echo "(It may take up to 15 min for the log upload to start on the device and the upload may take a long time depending on the log size)"

token=$(gcloud auth print-identity-token)
user_name=$(gcloud config get-value account)
base_name=$(echo "$user_name" | cut -d'@' -f1)
bucket_folder="$base_name/release-test-$(date +'%Y-%m-%d')-$DEVICE_ID"
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
  
  if [ "$USE_PROXY" = true ]; then
    location=$(echo "$location" | sed 's/storage.googleapis.com/firmware-logs.connectedcars.io/')
  fi
  
  echo "$location"
}

accel_url=$(get_bucket_url "$accel_dist")
can_url=$(get_bucket_url "$can_dist")
journald_url=$(get_bucket_url "$journald_dist")
state_url=$(get_bucket_url "$state_dist")

# Calculate validUntil time based on provided duration (in hours)
valid_until=$(date -u -d "$DURATION hour" +'%Y-%m-%dT%H:%M:%S.000Z')

echo "Accel logs: $accel_url"
echo "Can logs: $can_url"
echo "Journald logs: $journald_url"
echo "State logs: $state_url"
echo "Command valid until: $valid_until"

echo "Assembling GraphQL command..."

# Convert the ENABLE_SSH flag to JSON boolean
ssh_enabled_value=$( [ "$ENABLE_SSH" = true ] && echo true || echo false )

if [ "$ONLY_ACCEL" = true ]; then
log_cmd=$(cat <<EOF
  "{\"logs\": [
    {
      \"upload_url\": \"$accel_url\",
      \"compress\": false,
      \"log_type\": \"Accel\"
    }
  ],
    \"ssh\": $ssh_enabled_value
  }"
EOF
)
else
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
  ],
    \"ssh\": $ssh_enabled_value
  }"
EOF
)
fi


log_cmd_clean=$(echo "$log_cmd" | tr -d '\n' | tr -s ' ')

debug_cmd=$(cat <<EOF
mutation addDebugCommands {
  addUnitDebugCommand(input: {
    data: $log_cmd_clean,
    unitId: "$DEVICE_ID",
    validUntil: "$valid_until"
  })
}
EOF
)

echo "debug_cmd: $debug_cmd"

echo "Fetching tokens..."

GRAPHQL_ENDPOINT="https://api.connectedcars.io/graphql"
payload=$(jq -n --arg query "$debug_cmd" '{ query: $query }')
jwt_token=$(convert_google_token_to_jwt "$token")

echo "Sending upload command..."

response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "X-Organization-Namespace: cctech:workshop" \
  -H "Authorization: Bearer $jwt_token" \
  -d "$payload" \
  "$GRAPHQL_ENDPOINT")

if echo "$response" | grep -q '"addUnitDebugCommand":true'; then
  echo -e "\033[1;32mLog-upload command sent successfully. Find them here:\033[0m"
  dist_link="https://console.cloud.google.com/storage/browser/device-debugging-logs/$bucket_folder?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&authuser=2&inv=1&invt=AbmZ4Q&project=connectedcars-147810"
  echo -e "\033[4;34m$dist_link\033[0m"
else
  echo -e "\033[1;31mFailed to send log-upload command.\033[0m"
  echo "Response: $response"
  exit 1
fi



#---------------------------------------- Original Script ----------------------------------------#


# #!/bin/bash

# if [ -z "$1" ]; then
#   echo "Please provide device ID"
#   exit 1
# fi

# echo "Uploading logs for device $1"
# echo "(It may take up to 15 min for the log upload to start on the device and the upload may take a long time depending on the log size)"

# token=$(gcloud auth print-identity-token)
# user_name=$(gcloud config get-value account)
# base_name=$(echo "$user_name" | cut -d'@' -f1)
# bucket_folder="$base_name/release-test-$(date +'%Y-%m-%d')-$1"
# accel_dist="$bucket_folder/accel"
# can_dist="$bucket_folder/can"
# journald_dist="$bucket_folder/journald"
# state_dist="$bucket_folder/state"

# convert_google_token_to_jwt() {
#   local google_token=$1
#   local api_url="https://auth-api.connectedcars.io/auth/login/googleConverter"
#   local jwt_token

#   jwt_token=$(curl -s -X POST "$api_url" \
#     -H "X-Organization-Namespace: cctech:workshop" \
#     -H "Accept: application/json" \
#     -H "Content-Type: application/json" \
#     -d "{\"token\": \"$google_token\"}" | jq -r '.token')

#   if [ -z "$jwt_token" ] || [ "$jwt_token" == "null" ]; then
#     echo "Error: Failed to convert Google token to JWT token"
#     return 1
#   fi

#   echo "$jwt_token"
#   return 0
# }

# echo "Creating bucket for logs..."

# get_bucket_url() {
#   response=$(curl -s -i -X POST -H "Authorization: Bearer $(gcloud auth print-access-token)" \
#       "https://storage.googleapis.com/upload/storage/v1/b/device-debugging-logs/o?uploadType=resumable&name=$1")
#   location=$(echo "$response" | grep -i "location:" | awk '{print $2}' | tr -d '\r')
#   # proxy option 
#   location=$(echo "$location" | sed 's/storage.googleapis.com/firmware-logs.staging.connectedcars.io/')
#   echo "$location"
# }
# accel_url=$(get_bucket_url "$accel_dist")
# can_url=$(get_bucket_url "$can_dist")
# journald_url=$(get_bucket_url "$journald_dist")
# state_url=$(get_bucket_url "$state_dist")

# # Time option 
# one_hour_from_now=$(date -u -d '6 hour' +'%Y-%m-%dT%H:%M:%S.000Z')

# echo "Accel logs: $accel_url"
# echo "Can logs: $can_url"
# echo "Journald logs: $journald_url"
# echo "State logs: $state_url"


# echo "Assembling GraphQL command..."


# # add ssh option 
# log_cmd=$(cat <<EOF
#   "{\"logs\": [
#     {
#       \"upload_url\": \"$accel_url\",
#       \"compress\": false,
#       \"log_type\": \"Accel\"
#     },
#     {
#       \"upload_url\": \"$can_url\",
#       \"compress\": false,
#       \"log_type\": \"Can\"
#     },
#     {
#       \"upload_url\": \"$journald_url\",
#       \"compress\": true,
#       \"log_type\": \"Journal\"
#     },
#     {
#       \"upload_url\": \"$state_url\",
#       \"compress\": true,
#       \"log_type\": \"State\"
#     }
#   ]}"
# EOF
# )

# log_cmd_clean=$(echo "$log_cmd" | tr -d '\n' | tr -s ' ')

# debug_cmd=$(cat <<EOF
# mutation addDebugCommands {
#   addUnitDebugCommand(input: {
#     data: $log_cmd_clean,
#     unitId: "$1",
#     validUntil: "$one_hour_from_now"
#   })
# }
# EOF
# )

# echo "Fetching tokens..."

# # Define the GraphQL endpoint
# GRAPHQL_ENDPOINT="https://api.connectedcars.io/graphql"
# payload=$(jq -n --arg query "$debug_cmd" '{ query: $query }')
# jwt_token=$(convert_google_token_to_jwt "$token")

# echo "Sending upload command..."

# # Send the request and capture the response
# response=$(curl -s -X POST \
#   -H "Content-Type: application/json" \
#   -H "X-Organization-Namespace: cctech:workshop" \
#   -H "Authorization: Bearer $jwt_token" \
#   -d "$payload" \
#   "$GRAPHQL_ENDPOINT")

# # Check if the response contains success
# if echo "$response" | grep -q '"addUnitDebugCommand":true'; then
#   echo -e "\033[1;32mLog-upload command sent successfully. Find them here:\033[0m"
#   dist_link="https://console.cloud.google.com/storage/browser/device-debugging-logs/$bucket_folder?pageState=(%22StorageObjectListTable%22:(%22f%22:%22%255B%255D%22))&authuser=2&inv=1&invt=AbmZ4Q&project=connectedcars-147810"
#   echo -e "\033[4;34m$dist_link\033[0m"
# else
#   echo -e "\033[1;31mFailed to send log-upload command.\033[0m"
#   echo "Response: $response"
#   exit 1
# fi