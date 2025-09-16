#!/bin/bash

# alias docker=nerdctl

# Step 1: Register DCR client
DCR_RESPONSE=$(curl -sk -X POST $DCR_ENDPOINT \
-H "Authorization: Basic YWRtaW46YWRtaW4=" \
-H "Content-Type: application/json" \
-d '{
    "callbackUrl": "www.google.lk",
    "clientName": "rest_api_client",
    "owner": "admin",
    "grantType": "password refresh_token",
    "saasApp": true
}')
# Extract clientId and clientSecret using grep and awk
CLIENT_ID=$(echo $DCR_RESPONSE | grep -o '"clientId":"[^"]*' | awk -F'"' '{print $4}')
CLIENT_SECRET=$(echo $DCR_RESPONSE | grep -o '"clientSecret":"[^"]*' | awk -F'"' '{print $4}')

# Step 2: Base64 encode clientId:clientSecret
ENCODED_CREDENTIALS=$(echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64)

# Step 3: Get access token
ACCESS_TOKEN=$(curl -sk $TOKEN_ENDPOINT \
-H "Authorization: Basic $ENCODED_CREDENTIALS" \
-d "grant_type=password&username=admin&password=admin&scope=apim:common_operation_policy_manage" | grep -o '"access_token":"[^"]*' | awk -F'"' '{print $4}')

PUBLISHER_URL="$APIM_URL/api/am/publisher/v4/operation-policies"
# For every folder matching org.wso2.am.policies.mediation.ai.*
for dir in ./AIPolicies/org.wso2.am.policies.mediation.ai.*; do
    policySpecFile="$dir/policy-definition.json"
    synapsePolicyFile="$dir/artifact.j2"

    # Only proceed if both files exist
    if [[ -f "$policySpecFile" && -f "$synapsePolicyFile" ]]; then
        echo "Uploading policy from $dir..."
        curl -k $PUBLISHER_URL \
             -H "Authorization: Bearer $ACCESS_TOKEN" \
             -H "Content-Type: multipart/form-data" \
             -F "policySpecFile=@${policySpecFile}" \
             -F "synapsePolicyDefinitionFile=@${synapsePolicyFile}"
    else
        echo "Skipping $dir — required files not found."
    fi
done
