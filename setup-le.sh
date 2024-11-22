#!/usr/bin/bash
set -o nounset -o errexit

EMAIL=""
FQDN=$(hostname -f)
WORKDIR=$(dirname "$(realpath $0)")

# Dump root certs into /etc/ssl/$FQDN/. This will add them to the system truststore
CERTS=("gts-root-r4.pem" "isrg-root-x2.pem" "usertrust-ca.pem" "zerossl_ca.pem")
sed -i "s/server.example.test/$FQDN/g" $WORKDIR/ipa-httpd.cnf

if [ ! -d "/etc/ssl/$FQDN" ]
then
  mkdir -p "/etc/ssl/$FQDN"
fi

for CERT in "${CERTS[@]}"
do
  cp "$WORKDIR/$CERT" "/etc/ssl/$FQDN/$CERT"
  ipa-cacert-manage install "/etc/ssl/$FQDN/$CERT"
done
ipa-certupdate

# cleanup
rm -f "$WORKDIR"/*.pem
rm -f "$WORKDIR"/httpd-csr.*

# httpd process prevents letsencrypt from working, stop it
if ! command -v service >/dev/null 2>&1; then
	systemctl stop httpd
else
	service httpd stop
fi

# generate CSR from existing private key. Do not replace existing private key, as a lot of FreeIPA services expect it
# Instead of replacing it, we will generate a CSR and get ZeroSSL to sign it
OPENSSL_PASSWD_FILE="/var/lib/ipa/passwds/$HOSTNAME-443-RSA"
[ -f "$OPENSSL_PASSWD_FILE" ] && OPENSSL_EXTRA_ARGS="-passin file:$OPENSSL_PASSWD_FILE" || OPENSSL_EXTRA_ARGS=""
openssl req -new -sha256 -config "$WORKDIR/ipa-httpd.cnf" -key /var/lib/ipa/private/httpd.key -out "$WORKDIR/httpd-csr.der" $OPENSSL_EXTRA_ARGS

mv /var/lib/ipa/certs/$FQDN.cer httpd.crt
restorecon -v /var/lib/ipa/certs/httpd.crt

# start httpd with the new cert
if ! command -v service >/dev/null 2>&1; then
	systemctl start httpd
else
	service httpd start
fi
