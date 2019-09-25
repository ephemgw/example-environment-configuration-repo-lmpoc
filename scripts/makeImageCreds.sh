#!/bin/bash
echo "Usage: ./makeSecret.sh -namespace=default -dest=destination.yaml -password=password"

for ARGUMENT in "$@"
do
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            -namespace)             namespace=${VALUE} ;;
            -password)           password=${VALUE} ;;
            -dest)                  destination=${VALUE} ;;
            *)
    esac
done

OUT="$(mktemp)"
echo "imageCredentials:" >> "$OUT"
echo "  password: \"$password\"" >> "$OUT"
kubectl create secret generic image-creds --dry-run  -n "$namespace"  -o yaml --from-file=image-creds.yaml="$OUT" | kubeseal --format yaml > "$destination"
if [ $? -eq 0 ]; then
    echo "Secret created in $destination"
else
    echo Failed to create secret
fi

rm "$OUT"