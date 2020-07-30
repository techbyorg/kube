#!/bin/bash

[ -z "$TAG" ] && TAG=latest
[ -z "$TIMESTAMP" ] && TIMESTAMP=$(date +%s)
NAMESPACE="$1"
FILE="$2"


if [ "$NAMESPACE" == "-h" ] || [ "$NAMESPACE" == "" ]; then
  cat << EOF
Env ~ envify template files

Usage:
  ./template.sh NAMESPACE FILE

Example:
  kubectl apply -f $(./template.sh staging controllers/xxxx.yaml)

EOF
  exit 0
fi

if [ ! -e $FILE ]; then
  echo "File not found at $FILE"
  exit 1
fi

TEMP_FILE=$(mktemp).yaml
# compgen / sed stuff is to only replace defined vars
source ./secrets/$NAMESPACE.env.sh
cat $FILE | env -i bash -c "source ./secrets/$NAMESPACE.env.sh && TAG=$TAG TIMESTAMP=$TIMESTAMP NAMESPACE=$NAMESPACE envsubst '\$$(compgen -v | sed ':a;N;$!ba;s/\n/:\$/g')'" > $TEMP_FILE

echo $TEMP_FILE
