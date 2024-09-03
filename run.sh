#!/bin/sh

CONTAINER=p11-container
PROVIDER=/usr/lib/x86_64-linux-gnu/pkcs11/libtpm2_pkcs11.so
TPM2_PKCS11_STORE="$(pwd)"

export TPM2_PKCS11_STORE

if [ -z "$(docker images -q ${CONTAINER})" ]; then
    docker build -t ${CONTAINER} - <<EOF
FROM alpine:3.20
RUN apk add --no-cache p11-kit-server opensc
RUN mkdir -p /etc/pkcs11/modules && echo "module: /usr/lib/pkcs11/p11-kit-client.so" | tee /etc/pkcs11/modules/p11-kit-client.module
RUN echo "alias p11cmd='pkcs11-tool --module /usr/lib/pkcs11/p11-kit-client.so'" | tee /etc/profile.d/alias.sh
CMD ["/bin/sh", "-l"]
EOF
fi

eval "$(p11-kit server --provider "${PROVIDER}" "pkcs11:")"
docker run --rm -it -v "${P11_KIT_SERVER_ADDRESS#*=}":"${P11_KIT_SERVER_ADDRESS#*=}" -e P11_KIT_SERVER_ADDRESS="${P11_KIT_SERVER_ADDRESS}" ${CONTAINER}
kill -15 "${P11_KIT_SERVER_PID}"
