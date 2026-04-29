#!/bin/bash

# Run hooks
for file in /hooks/*; do
  if [ -x "${file}" ]; then
    echo "Running hook ${file}"
    "${file}"
  fi
done

if [[ ! -z ${REDIS_SLAVEOF_IP} ]]; then
  cp /etc/syslog-ng/syslog-ng-redis_slave.conf /etc/syslog-ng/syslog-ng.conf
fi

# Fix OpenSSL 3.X TLS1.0, 1.1 support (https://community.mailcow.email/d/4062-hi-all/20)
if grep -qE '\!SSLv2|\!SSLv3|>=TLSv1(\.[0-1])?$' /opt/postfix/conf/main.cf /opt/postfix/conf/extra.cf; then
    sed -i '/\[openssl_init\]/a ssl_conf = ssl_configuration' /etc/ssl/openssl.cnf

    echo "[ssl_configuration]" >> /etc/ssl/openssl.cnf
    echo "system_default = tls_system_default" >> /etc/ssl/openssl.cnf
    echo "[tls_system_default]" >> /etc/ssl/openssl.cnf
    echo "MinProtocol = TLSv1" >> /etc/ssl/openssl.cnf
    echo "CipherString = DEFAULT@SECLEVEL=0" >> /etc/ssl/openssl.cnf
fi  

# Set Postfix-specific OpenSSL signature algorithms
sed -i '/\[openssl_init\]/a postfix = postfix_settings' /etc/ssl/openssl.cnf
cat >> /etc/ssl/openssl.cnf <<'EOF'

[postfix_settings]
ssl_conf = postfix_ssl_settings

[postfix_ssl_settings]
system_default = baseline_postfix_settings

[baseline_postfix_settings]
SignatureAlgorithms = ECDSA+SHA256:ECDSA+SHA384:ECDSA+SHA512:RSA-PSS+SHA256:RSA-PSS+SHA384:RSA-PSS+SHA512:RSA+SHA512:RSA+SHA256:RSA+SHA384
EOF

exec "$@"
