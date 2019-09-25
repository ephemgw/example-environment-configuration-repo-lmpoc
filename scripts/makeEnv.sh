#!/bin/bash
echo "Usage: ./makeEnv.sh -namespace=default -dest=destination.yaml -ext=json"

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            -namespace)             namespace=${VALUE} ;;
            -dest)                  destination=${VALUE} ;;
            -ext)
                if [ ${VALUE} != "json" ] && [ ${VALUE} != "yaml" ]; then
                    echo "Please enter either json or yaml for ext parameter."
                fi           
                extension=${VALUE} ;;
            *)
    esac
done

# HELPER FUNCTIONS
function format_json () {
    tempFile="$(mktemp)"
    grep . "$ENTRY" | while IFS= read -r line
    do
        if [[ $line = \{* || $line = \}* ]]; then
            :
        elif [[ $line =~ ^[[:space:]][[:space:]]\" ]]; then
            line=`echo $line | cut -d'"' -f2`
            line="$1.$line: '{"
            echo "$line"
        elif [[ $line = [[:space:]][[:space:]]\} || $line = [[:space:]][[:space:]]\}\, ]]; then
            line=`echo $line | sed 's/[^0-9A-Za-z: }]*//g'`
            echo " $line'"
        else
            echo "$line"
        fi
    done > "$tempFile"

    cat "$tempFile" | sed 's/^/    /' >> "$OUT"
    rm "$tempFile"
}

function format_yaml () {
    tempFile="$(mktemp)"
    grep . "$ENTRY" | while IFS= read -r line
    do
        if [[ $line =~ ^[[:alnum:]] ]]; then
            line="$1.$line |-"
            echo "$line"
        else
            echo "$line"
        fi
    done > "$tempFile"

    cat "$tempFile" | sed 's/^/    /' >> "$OUT"
    rm "$tempFile"
}

function format_properties () {
    tempFile="$(mktemp)"
    grep . "$ENTRY" | while IFS= read -r line
    do
        key=$(echo "$line" | awk -F '=' '{print $1}')
        value=$(echo "$line" | awk -F '=' '{print $2}')
        echo "$1.$key: \"$value\""
    done > "$tempFile"

    cat "$tempFile" | sed 's/^/    /' >> "$OUT"
    rm "$tempFile"
}

function format_cert_file () {
    tempFile="$(mktemp)"
    for ENTRY in "certificates/"*
    do
        name=$(echo "$ENTRY" | awk -F '/' '{print $2}')
        echo "ENV.CERTIFICATE_FILE.$name: |-" > "$tempFile"
        grep . "$ENTRY" | while IFS= read -r line
        do
            echo "    $line"
        done >> "$tempFile"
        cat "$tempFile" | sed 's/^/    /' >> "$OUT"
    done

    rm "$tempFile"
}

function encrypt_private_key () {
    kubectl create secret generic gateway-private-keys --dry-run  -n "$namespace"  -o yaml --from-file=privateKeys  | kubeseal --format yaml > "../releases/"$namespace"/privateKeys.yaml"
    kubectl create -f ../releases/"$namespace"/privateKeys.yaml > /dev/null

    echo "    gatewayPrivateKeys: \"true\"" >> "$OUT"
}

# Set base template for env.yaml
OUT="$(mktemp)"
echo "gateway:" >> "$OUT"
echo "  env:" >> "$OUT"
echo "    ENV.CONTEXT_VARIABLE_PROPERTY.influxdb.influxdb: \"apim-service-metrics-runtime-influxdb.default\"" >> "$OUT"
echo "    ENV.CONTEXT_VARIABLE_PROPERTY.influxdb.tags: \"env=$namespace\"" >> "$OUT"

# Remove private key related secrets
if [ -f "../releases/$namespace/privateKeys.yaml" ]; then
    rm "../releases/$namespace/privateKeys.yaml"
fi
if [[ ! -z $(kubectl get SealedSecrets -n "$namespace" | grep gateway-private-keys) ]]; then 
        kubectl delete SealedSecrets gateway-private-keys -n "$namespace" > /dev/null
    fi

# Add in necessary entities
for ENTRY in *
do
    if [ "$extension" = "json" ]; then
        case $ENTRY in
        # Cassandra Connections
        "cassandra-connections.json")
            format_json "ENV.CASSANDRA_CONNECTION"
            ;;
        # Identity Providers
        "identity-providers.json")
            format_json "ENV.IDENTITY_PROVIDER"
            ;;
        # JDBC Connections
        "jdbc-connections.json")
            format_json "ENV.JDBC_CONNECTION"
            ;;
        # JMS Destinations
        "jms-destinations.json")
            format_json "ENV.JMS_DESTINATION"
            ;;
        # Listen Ports
        "listen-ports.json")
            format_json "ENV.LISTEN_PORT"
            ;;
        # Private Keys
        "private-keys.json")
            format_json "ENV.PRIVATE_KEY"
            ;;
        # Private Keys Files
        "privateKeys")
            encrypt_private_key
            ;;
        # Trusted Certificates
        "trusted-certs.json")
            format_json "ENV.CERTIFICATE"
            ;;
        # Trusted Certificates Files
        "certificates")
            format_cert_file
            ;;
        # Global Environment Properties
        "global-env.properties")
            format_properties "ENV.PROPERTY"
            ;;
        # Context Environment Properties
        "context-env.properties")
            format_properties "ENV.CONTEXT_VARIABLE_PROPERTY"
            ;;
        # Service Environment Properties
        "service-env.properties")
            format_properties "ENV.SERVICE_PROPERTY"
            ;;
        # Stored Passwords
        "stored-passwords.properties")
            format_properties "ENV.PASSWORD"
            ;;
        esac
    elif [ "$extension" = "yaml" ]; then
        case $ENTRY in
        # Cassandra Connections
        "cassandra-connections.yml")
            format_yaml "ENV.CASSANDRA_CONNECTION"
            ;;
        # Identity Providers
        "identity-providers.yml")
            format_yaml "ENV.IDENTITY_PROVIDER"
            ;;
        # JDBC Connections
        "jdbc-connections.yml")
            format_yaml "ENV.JDBC_CONNECTION"
            ;;
        # JMS Destinations
        "jms-destinations.yml")
            format_yaml "ENV.JMS_DESTINATION"
            ;;
        # Listen Ports
        "listen-ports.yml")
            format_yaml "ENV.LISTEN_PORT"
            ;;
        # Private Keys
        "private-keys.yml")
            format_yaml "ENV.PRIVATE_KEY"
            ;;
        # Private Keys Files
        "privateKeys")
            encrypt_private_key
            ;;
        # Trusted Certificates
        "trusted-certs.yml")
            format_yaml "ENV.CERTIFICATE"
            ;;
        # Trusted Certificates Files
        "certificates")
            format_cert_file
            ;;
        # Global Environment Properties
        "global-env.properties")
            format_properties "ENV.PROPERTY"
            ;;
        # Context Environment Properties
        "context-env.properties")
            format_properties "ENV.CONTEXT_VARIABLE_PROPERTY"
            ;;
        # Service Environment Properties
        "service-env.properties")
            format_properties "ENV.SERVICE_PROPERTY"
            ;;
        # Stored Passwords
        "stored-passwords.properties")
            format_properties "ENV.PASSWORD"
            ;;
        esac
    fi
done


cat "$OUT" > "env.yaml"
kubectl create secret generic env --dry-run  -n "$namespace"  -o yaml --from-file="env.yaml"  | kubeseal --format yaml > "$destination"

if [ $? -eq 0 ]; then
    echo "Secret created in $destination"
else
    echo Failed to create secret
fi

rm "$OUT"