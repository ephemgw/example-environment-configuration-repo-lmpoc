#!/bin/bash
echo "Usage: ./makeLicense.sh -namespace=default -dest=destination.yaml -license=license.xml"
echo "hi1"
for ARGUMENT in "$@"

do
	echo "hi222"
    KEY=$(echo "$ARGUMENT" | cut -f1 -d=)
    VALUE=$(echo "$ARGUMENT" | cut -f2 -d=)

    case "$KEY" in
            -namespace)             namespace=${VALUE} ;;
            -license)               license=${VALUE} ;;
            -dest)                  destination=${VALUE} ;;
            *)
    esac
done

echo "By running this script, setting the ACCEPT_LICENSE environment variable to true.\nYou are expressing that you have a valid and existing commercial license for CA API Gateway and that you have reviewed and accepted the terms of the CA End User License Agreement (EULA), which shall govern your use of the CA API Gateway.\nDo you accept to run this script?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) echo "Exiting script"; exit;;
    esac
done

OUT="$(mktemp)"
echo "gateway:" >> "$OUT"
echo "  license:" >> "$OUT"
echo "    accept: \"true\"" >> "$OUT"
echo "    value: |+" >> "$OUT"
awk  '{ print "      " $0 }'  "$license" >> "$OUT"
kubectl create secret generic gateway-license --dry-run  -n "$namespace"  -o yaml --from-file=license.yaml="$OUT"  | kubeseal --format yaml > "$destination"
if [ $? -eq 0 ]; then
    echo "Secret created in $destination"
else
    echo Failed to create secret
fi

rm "$OUT"