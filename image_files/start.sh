#!/bin/bash

echo "$(date) - Checking heap size"
if [ -v HEAP_SIZE -a "${HEAP_SIZE}" != "" ]
then
    initial_heap_size_pattern="-Xms${HEAP_SIZE}g"
    max_heap_size_pattern="-Xmx${HEAP_SIZE}g"

    if grep -xq "^-Xms.*g" /etc/elasticsearch/jvm.options
    then
        if ! grep -xq "^${initial_heap_size_pattern}" /etc/elasticsearch/jvm.options
        then
            sed -i "s/^-Xms.*g/$initial_heap_size_pattern/g" /etc/elasticsearch/jvm.options
        fi
    else
        echo -e "# Initial heap size\n${initial_heap_size_pattern}" >> /etc/elasticsearch/jvm.options
    fi

    if grep -xq "^-Xmx.*g" /etc/elasticsearch/jvm.options
    then
        if ! grep -xq "^${max_heap_size_pattern}" /etc/elasticsearch/jvm.options
        then
            sed -i "s/^-Xmx.*g/$max_heap_size_pattern/g" /etc/elasticsearch/jvm.options
        fi
    else
        echo -e "# Max heap size\n${max_heap_size_pattern}" >> /etc/elasticsearch/jvm.options
    fi
fi

CERT_FILE=/etc/elasticsearch/elastic-certificates.p12

if [ -v SECURITY_ENABLE -a "${SECURITY_ENABLE}" == true -a ! -f "$CERT_FILE" ]
then
    echo "$(date) - Setting up elastic search security"
    echo "$(date) - Stopping elasticsearch service"
    /etc/init.d/elasticsearch stop
    cd /usr/share/elasticsearch/bin/
    ./elasticsearch-certutil cert -out /etc/elasticsearch/elastic-certificates.p12  -pass ""
    chmod 664 /etc/elasticsearch/elastic-certificates.p12
    #sed: cannot rename /etc/elasticsearch/sedXdVDys: Device or resource busy
    cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch_yml_tmp
    sed -i '/^xpack/s/^\(.*\)$/#\1/' /etc/elasticsearch/elasticsearch_yml_tmp
    cp -f /etc/elasticsearch/elasticsearch_yml_tmp /etc/elasticsearch/elasticsearch.yml
    rm /etc/elasticsearch/elasticsearch_yml_tmp
    echo -e '# Elasticsearch security configurations
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12' >> /etc/elasticsearch/elasticsearch.yml
    echo "$(date) - Starting elasticsearch service"
    /etc/init.d/elasticsearch start
    sleep 10
    echo "create password file at /passwords"
    ./elasticsearch-setup-passwords auto -b > /passwords
else
    if [ -f "$CERT_FILE" ]
    then
        echo "${CERT_FILE} exists. Elasticsearch security is already enabled"
    else
        echo "Elasticsearch security isn't enabled. Use SECURITY_ENABLE=true to enable security"
    fi
fi


echo "$(date) - Starting elasticsearch"
/etc/init.d/elasticsearch start && tail -f /dev/null
