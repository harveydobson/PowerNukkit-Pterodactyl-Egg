#!/bin/bash
# PowerNukkit Installation Script
#
# Server Files: /mnt/server
apt update
apt install -y curl jq

if [ -n "${DL_PATH}" ]; then
    echo -e "Using supplied download url: ${DL_PATH}"
    DOWNLOAD_URL=`eval echo $(echo ${DL_PATH} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
else
    LAST_SUCCESS=`curl -sLH 'accept: application/json' -X 'GET' "https://builds.powernukkit.org/app/rest/builds/?locator=buildType:${RELEASE_CHANNEL},status:success,count:1"`
    EXISTS=`echo "$LAST_SUCCESS" | jq '.count == 1' 2> /dev/null`
    if [ "${EXISTS}" != "true" ]; then
        RELEASE_CHANNEL=PowerNukkit_Releases
        LAST_SUCCESS=`curl -sLH 'accept: application/json' -X 'GET' "https://builds.powernukkit.org/app/rest/builds/?locator=buildType:${RELEASE_CHANNEL},status:success,count:1"`
        EXISTS=`echo "$LAST_SUCCESS" | jq '.count == 1' 2> /dev/null`
        if [ "${EXISTS}" != "true" ]; then
            echo "Could not update the server jar!"
        fi
    fi
    if [ "${EXISTS}" == "true" ]; then
        BUILD_NUMBER=`echo "$LAST_SUCCESS" | jq '.build[0].id'`
        FILE=`curl -sLH 'accept: application/json' -X 'GET' "https://builds.powernukkit.org/app/rest/builds/${BUILD_NUMBER}/artifacts"`
        FILE=`echo $FILE | jq '.file[] | select(.name | endswith("-shaded.jar")) | .content.href' 2> /dev/null`
        if [ -z "$FILE" ]; then
            echo "Could not find the artifact of the build $BUILD_NUMBER to update the server jar!"
        else
            DOWNLOAD_URL=`echo "https://builds.powernukkit.org$FILE" | sed 's/"//g'`
			echo "Found a download at $DOWNLOAD_URL"
        fi
    fi
fi

cd /mnt/server
echo -e "Running curl -Lo ${SERVER_JARFILE} ${DOWNLOAD_URL}"
if [ -f "${SERVER_JARFILE}" ]; then
    mv "${SERVER_JARFILE}" "${SERVER_JARFILE}.old"
fi

curl -Lo "${SERVER_JARFILE}" "${DOWNLOAD_URL}"
if [ ! -f server.properties ]; then
    echo '#Minecraft server properties' > server.properties
    echo 'server-port=19132' >> server.properties
    echo 'server-ip=0.0.0.0' >> server.properties
fi
