#!/bin/bash

set -e

# Define the path to the example configuration file
TEMPLATE_CONF="keydb.conf"

# First pass: Evaluate any nested variables within .env file and export them
while IFS='=' read -r key value || [[ -n $key ]]; do
    # Skip comments and empty lines
    [[ $key =~ ^#.* ]] || [[ -z $key ]] && continue
    
    # Removing any quotes around the value
    value=${value%\"}
    value=${value#\"}
    
    # Evaluate any variables within value
    eval "value=\"$value\""
    
    export "$key=$value"
done < .env

# Copy the example conf to the destination to start replacing the variables
cp "$TEMPLATE_CONF" "$REDIS_CONFIG"

# Second pass: Replace the variables in $REDIS_CONFIG
while IFS='=' read -r key value || [[ -n $key ]]; do
    # Skip comments and empty lines
    [[ $key =~ ^#.* ]] || [[ -z $key ]] && continue
    
    value=${!key} # Get the value of the variable whose name is $key
    
    # Escape characters which are special to sed
    value_escaped=$(echo "$value" | sed 's/[\/&]/\\&/g')
    
    # Replace occurrences of the key with the value in $REDIS_CONFIG
    sed -i "s/\${$key}/${value_escaped}/g" "$REDIS_CONFIG"
done < .env

echo "Configuration file is generated at $REDIS_CONFIG"
