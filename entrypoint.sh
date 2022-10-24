#!/bin/bash

VAULT="$1"
# Could also allow users to specify secret_type::secret_name so they could 
#  read secrets, certs and keys from a single step
SECRET_TYPE="$2"
# Read in and split keys
KEYS=${3//,/ }
OUTPUT_ENVS="$4"
OUTPUT_OUTPUTS="$5"
DEBUG="${DEBUG:-false}"

test -z "${VAULT}" && echo "input.vault-name must be specified" && exit 1
test -z "${SECRET_TYPE}" && echo "input.type must be specified" && exit 2
test -z "${KEYS}" && echo "input.keys must be specified" && exit 4

function debug(){
    if [[ "${DEBUG}" == "true" ]]; then
        echo $@
    fi
}

debug "DEBUG MODE : ${DEBUG}"
debug "INPUTS\n------------"
debug "input.vault-name=${VAULT}"
debug "input.type=${SECRET_TYPE}"
debug "input.keys=${KEYS}"
debug "input.output-envs=${OUTPUT_ENVS}"
debug "input.output-outputs=${OUTPUT_OUTPUTS}"

# Iterate through all KEYS
for key in ${KEYS[@]}; do
    debug "Using key: \"${key}\""
    # Remove non alpha-numeric characters with underscore (_)
    SAFE_KEY=$(echo ${key} | sed -E 's/[^[:alnum:]]+/_/g')
    
    debug "Transformed: \"${key}\" --> \"${SAFE_KEY}\""

    debug "Running: az keyvault ${SECRET_TYPE} show --name \"${key}\" --vault-name \"${VAULT}\" --query \"value\""

    # Get the key
    val=$(az keyvault ${SECRET_TYPE} show --name "${key}" --vault-name "${VAULT}" --query "value")
    # Mask the secret in logs
    echo "::add-mask::${val}"
    
    # Add to the environment
    if [[ "${OUTPUT_ENVS}" == "true" ]]; then
        echo "Creating environment variable: ${SAFE_KEY}"
        echo "${SAFE_KEY}=${val}" >> $GITHUB_ENV
    fi

    # Add to the step's outputs
    if [[ "${OUTPUT_OUTPUTS}" == "true" ]]; then
        echo "Creating step output: ${SAFE_KEY}"
        echo "${SAFE_KEY}=${val}" >> $GITHUB_OUTPUT
    fi
done
