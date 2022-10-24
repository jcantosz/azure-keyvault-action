#!/bin/bash

VAULT="$1"
# Could also allow users to specify secret_type::secret_name so they could 
#  read secrets, certs and keys from a single step
SECRET_TYPE="$2"
KEYS="$3"
OUTPUT_ENV="$4"
OUTPUT_OUTPUTS="$5"

test -z "${VAULT}" && echo "input.vault-name must be specified" && exit 1
test -z "${SECRET_TYPE}" && echo "input.type must be specified" && exit 2
test -z "${KEYS}" && echo "input.keys must be specified" && exit 4

# Iterate through all KEYS (replace comma with space and let bash do its magic)
for key in ${KEYS//,/ }; do
    # Remove non alpha-numeric characters with underscore (_)
    SAFE_KEY=$(sed -E 's/[^[:alnum:]]+/_/g')

    # Get the key
    val=$(az keyvault ${SECRET_TYPE} show --name "${key}" --vault-name "${VALUT}" --query "value")
    # Mask the secret in logs
    echo "::add-mask::${val}"
    
    # Add to the environment
    if [[ "${OUTPUT_ENV}" == "true" ]]; then
        echo "Creating environment variable: ${SAFE_KEY}"
        echo "${SAFE_KEY}=${val}" >> $GITHUB_ENV
    fi

    # Add to the step's outputs
    if [[ "${OUTPUT_OUTPUTS}" == "true" ]]; then
        echo "Creating step output: ${SAFE_KEY}"
        echo "${SAFE_KEY}=${val}" >> $GITHUB_OUTPUT
    fi
done
