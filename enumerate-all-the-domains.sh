#! /bin/bash

DOMAINS_FILE=$1
OUTPUT_DIR=$2

if [[ -z $DOMAINS_FILE ]] || [[ -z $OUTPUT_DIR ]]; then
	echo "Usage: $0 <domains-file> <output-dir>"
	exit 1
fi

source .env

# Creating directories
mkdir -p $OUTPUT_DIR $OUTPUT_DIR/subdomains

# Subdomain enum
if [[ ! -z $CHAOS_API_KEY ]]; then
	chaos -silent -key "$CHAOS_API_KEY" -o "$OUTPUT_DIR/subdomains/chaos.txt" -dL $DOMAINS_FILE 1>/dev/null
fi

subfinder -silent -dL $DOMAINS_FILE -o $OUTPUT_DIR/subdomains/subfinder.txt 1>/dev/null

while read -r DOMAIN; do
	curl -s https://crt.sh/\?q\=\%.$DOMAIN\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u >> $OUTPUT_DIR/subdomains/crtsh.txt
	sublist3r -d $DOMAIN -o $OUTPUT_DIR/subdomains/sublist3r-$DOMAIN.txt 1>/dev/null
	if [[ ! -z $SECURITY_TRAILS_API_KEY ]]; then
		curl "https://api.securitytrails.com/v1/domain/$DOMAIN/subdomains" -H "apikey: $SECURITY_TRAILS_API_KEY" | jq .subdomains[] | tr -d '"' | sed "s/\$/.$DOMAIN/" >> $OUTPUT_DIR/subdomains/securitytrails.txt
	fi
done < $DOMAINS_FILE

# Unifying subdomains
cat $OUTPUT_DIR/subdomains/* | sort | uniq > $OUTPUT_DIR/all-subdomains.txt

echo "Found $(wc -l $OUTPUT_DIR/all-subdomains.txt | cut -d' ' -f1) subdomains"
