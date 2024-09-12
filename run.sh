#!/bin/sh

CONTAINER=p11-container:ubuntu
PROVIDER=/usr/lib/x86_64-linux-gnu/pkcs11/libtpm2_pkcs11.so
TPM2_PKCS11_STORE="$(pwd)"

export TPM2_PKCS11_STORE

if [ -z "$(docker images -q ${CONTAINER})" ]; then
    docker build -t ${CONTAINER} - <<EOF
FROM ubuntu:24.04
RUN apt update && apt install -y p11-kit libengine-pkcs11-openssl openssl gnutls-bin
RUN mkdir -p /etc/pkcs11/modules && echo "module: /usr/lib/x86_64-linux-gnu/pkcs11/p11-kit-client.so" > /etc/pkcs11/modules/p11-kit-client.module
EOF
fi

eval "$(p11-kit server ${PROVIDER:+ --provider ${PROVIDER}} 'pkcs11:')"
docker run --rm -it -v "${P11_KIT_SERVER_ADDRESS#*=}":"${P11_KIT_SERVER_ADDRESS#*=}" -e P11_KIT_SERVER_ADDRESS="${P11_KIT_SERVER_ADDRESS}" ${CONTAINER}
kill -15 "${P11_KIT_SERVER_PID}"
