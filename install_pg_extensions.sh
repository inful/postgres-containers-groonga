#!/bin/bash
set -euxo pipefail

# calling syntax: install_pg_extensions.sh [extension1] [extension2] ...

# install extensions
EXTENSIONS="$@"
# cycle through extensions list
for EXTENSION in ${EXTENSIONS}; do
    # specail case: groonga
    if [ "$EXTENSION" == "groonga" ]; then
        # dependencies
        apt-get install ca-certificates lsb-release wget -y
        wget https://packages.groonga.org/debian/groonga-apt-source-latest-$(lsb_release --codename --short).deb
        apt install -y -V ./groonga-apt-source-latest-$(lsb_release --codename --short).deb
        rm ./groonga-apt-source-latest-$(lsb_release --codename --short).deb
        apt-get update
        apt install -y -V postgresql-${PG_MAJOR}-pgdg-pgroonga hunspell-en-us groonga-tokenizer-mecab
        mkdir -p /usr/share/postgresql/${PG_MAJOR}/tsearch_data
        ln -sf /usr/share/hunspell/en_US.dic /usr/share/postgresql/${PG_MAJOR}/tsearch_data/en_us.dict
        ln -sf /usr/share/hunspell/en_US.aff /usr/share/postgresql/${PG_MAJOR}/tsearch_data/en_us.aff
        ln -sf /zulip_english.top /usr/share/postgresql/${PG_MAJOR}/tsearch_data/zulip_english.stop
        # cleanup
        apt-get remove apt-transport-https lsb-release wget --auto-remove -y
        continue
    fi
    
    # special case: timescaledb
    if [ "$EXTENSION" == "timescaledb" ]; then
        # dependencies
        apt-get install apt-transport-https lsb-release wget -y

        # repository
        echo "deb https://packagecloud.io/timescale/timescaledb/debian/" \
            "$(lsb_release -c -s) main" \
            > /etc/apt/sources.list.d/timescaledb.list

        # key
        wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey \
            | gpg --dearmor > /etc/apt/trusted.gpg.d/timescaledb.gpg
        
        apt-get update
        apt-get install --yes \
            timescaledb-tools \
            timescaledb-toolkit-postgresql-${PG_MAJOR} \
            timescaledb-2-loader-postgresql-${PG_MAJOR} \
            timescaledb-2-${TIMESCALEDB_VERSION}-postgresql-${PG_MAJOR}

        # cleanup
        apt-get remove apt-transport-https lsb-release wget --auto-remove -y

        continue
    fi

    # is it an extension found in apt?
    if apt-cache show "postgresql-${PG_MAJOR}-${EXTENSION}" &> /dev/null; then
        # install the extension
        apt-get install -y "postgresql-${PG_MAJOR}-${EXTENSION}"
        continue
    fi

    # extension not found/supported
    echo "Extension '${EXTENSION}' not found/supported"
    exit 1
done
