#!/bin/bash

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# check if LOG_PREFIX is set
if [ -z "$LOG_PREFIX" ]; then
    LOG_PREFIX="\033[1m\033[33m🌐\u00A0\u00A0BUMBOOHOST\u00A0\u00A0🌐\u00A0\033[0m"
fi

# Switch to the container's working directory
cd /home/container || exit 1

# Print Java version
printf "\033[1m\033[38;5;208m 🌐\u00A0\u00A0BUMBOOHOST\u00A0\u00A0🌐 \033[0m\033[1m\033[33m🔍\u00A0\u00A0ĐANG KIỂM TRA PHIÊN BẢN JAVA\u00A0\u00A0🔍\033[0m\n"
java -version

JAVA_MAJOR_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')

if [[ "$MALWARE_SCAN" == "1" ]]; then
    # kiểm tra nếu phiên bản Java nhỏ hơn 17
    if [[ "$JAVA_MAJOR_VERSION" -lt 17 ]]; then
        echo -e "${LOG_PREFIX} \u00A0\u00A0🛡️\u00A0\u00A0 Quét phần mềm độc hại chỉ khả dụng với Java 17 trở lên, bỏ qua..."
        MALWARE_SCAN=0
    fi

    echo -e "${LOG_PREFIX} \u00A0\u00A0🛡️\u00A0\u00A0 Đang quét phần mềm độc hại... (Điều này có thể mất một lúc)"

    java -jar /MCAntiMalware.jar --scanDirectory . --singleScan true --disableAutoUpdate true

    if [ $? -eq 0 ]; then
        echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Quét phần mềm độc hại thành công"
    else
        echo -e "${LOG_PREFIX} \u00A0\u00A0❌\u00A0\u00A0 Quét phần mềm độc hại thất bại"
        exit 1
    fi
else
    echo -e "${LOG_PREFIX} \u00A0\u00A0🚫\u00A0\u00A0 Bỏ qua quét phần mềm độc hại..."
fi

if [[ "$AUTOMATIC_UPDATING" == "1" ]]; then
    if [[ "$SERVER_JARFILE" == "server.jar" ]]; then
        printf "${LOG_PREFIX} \u00A0\u00A0🔄\u00A0\u00A0 Đang kiểm tra phiên bản...\n"

        # Check if libraries/net/minecraftforge/forge exists
        if [ -d "libraries/net/minecraftforge/forge" ] && [ -z "${HASH}" ]; then
            # get first folder in libraries/net/minecraftforge/forge
            FORGE_VERSION=$(ls libraries/net/minecraftforge/forge | head -n 1)

            # Check if -server.jar or -universal.jar exists in libraries/net/minecraftforge/forge/${FORGE_VERSION}
            FILES=$(ls libraries/net/minecraftforge/forge/${FORGE_VERSION} | grep -E "(-server.jar|-universal.jar)")

            # Check if there are any files
            if [ -n "${FILES}" ]; then
                # get first file in libraries/net/minecraftforge/forge/${FORGE_VERSION}
                FILE=$(echo "${FILES}" | head -n 1)

                # Hash file
                HASH=$(sha256sum libraries/net/minecraftforge/forge/${FORGE_VERSION}/${FILE} | awk '{print $1}')
            fi
        fi

        # Check if libraries/net/neoforged/neoforge folder exists
        if [ -d "libraries/net/neoforged/neoforge" ] && [ -z "${HASH}" ]; then
            # get first folder in libraries/net/neoforged/neoforge
            NEOFORGE_VERSION=$(ls libraries/net/neoforged/neoforge | head -n 1)

            # Check if -server.jar or -universal.jar exists in libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}
            FILES=$(ls libraries/net/neoforged/neoforge/${NEOFORGE_VERSION} | grep -E "(-server.jar|-universal.jar)")

            # Check if there are any files
            if [ -n "${FILES}" ]; then
                # get first file in libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}
                FILE=$(echo "${FILES}" | head -n 1)

                # Hash file
                HASH=$(sha256sum libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}/${FILE} | awk '{print $1}')
            fi
        fi

        # Hash server jar file
        if [ -z "${HASH}" ]; then
            HASH=$(sha256sum $SERVER_JARFILE | awk '{print $1}')
        fi

        # Check if hash is set
        if [ -n "${HASH}" ]; then
            API_RESPONSE=$(curl -s "https://versions.mcjars.app/api/v1/build/$HASH")

            # Check if .success is true
            if [ "$(echo $API_RESPONSE | jq -r '.success')" = "true" ]; then
                if [ "$(echo $API_RESPONSE | jq -r '.build.id')" != "$(echo $API_RESPONSE | jq -r '.latest.id')" ]; then
                    echo -e "${LOG_PREFIX} \u00A0\u00A0🚀\u00A0\u00A0 Bản dựng mới đã được tìm thấy. Đang cập nhật ..."

                    BUILD_ID=$(echo $API_RESPONSE | jq -r '.latest.id')
                    bash <(curl -s "https://versions.mcjars.app/api/v1/script/$BUILD_ID/bash?echo=false")

                    echo -e "${LOG_PREFIX} \u00A0\u00A0🚀\u00A0\u00A0 Máy chủ đã được cập nhật"
                else
                    echo -e "${LOG_PREFIX} \u00A0\u00A0📅\u00A0\u00A0 Máy chủ được cập nhật"
                fi
            else
                echo -e "${LOG_PREFIX} \u00A0\u00A0⚠️\u00A0\u00A0 Không thể kiểm tra các bản cập nhật. Bỏ qua kiểm tra cập nhật."
            fi
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0⚠️\u00A0\u00A0 Không thể tìm thấy hàm hash. Bỏ qua kiểm tra cập nhật."
        fi
    else
        echo -e "${LOG_PREFIX} \u00A0\u00A0🛠️\u00A0\u00A0 Cập nhật tự động được bật, nhưng tệp jar máy chủ không phải là server.jar. Bỏ qua kiểm tra cập nhật."
    fi
fi

# check if libraries/net/minecraftforge/forge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/minecraftforge/forge" ] && [ ! -f "$SERVER_JARFILE" ]; then
    echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Tải xuống tệp jar máy chủ Forge..."
    curl -s https://s3.mcjars.app/forge/ForgeServerJAR.jar -o $SERVER_JARFILE

    echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Tệp jar Forge đã được tải xuống"
fi

# check if libraries/net/neoforged/neoforge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/neoforged/neoforge" ] && [ ! -f "$SERVER_JARFILE" ]; then
    echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Tải xuống tệp jar máy chủ NeoForge..."
    curl -s https://s3.mcjars.app/neoforge/NeoForgeServerJAR.jar -o $SERVER_JARFILE

    echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Tệp jar máy chủ NeoForge đã được tải xuống"
fi

# check if libraries/net/neoforged/forge exists and the SERVER_JARFILE file does not exist
if [ -d "libraries/net/neoforged/forge" ] && [ ! -f "$SERVER_JARFILE" ]; then
    echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Tải xuống tệp jar máy chủ NeoForge..."
    curl -s https://s3.mcjars.app/neoforge/NeoForgeServerJAR.jar -o $SERVER_JARFILE

    echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Tệp jar máy chủ NeoForge đã được tải xuống"
fi

# Kiểm tra nếu lệnh startup chứa -DPaper.WorkerThreadCount
if [[ "$SERVER_STARTUP" == *"-DPaper.WorkerThreadCount"* ]]; then
    echo -e "\033[1m\033[31m❌\u00A0\u00A0❌\u00A0\u00A0❌\u00A0\u00A0 LỆNH CHỨA '-DPaper.WorkerThreadCount' \u00A0\u00A0❌\u00A0\u00A0❌\u00A0\u00A0❌\033[0m"
    echo -e "\033[1m\033[31m🔴\u00A0\u00A0🔴\u00A0\u00A0 Đang dừng server... \u00A0\u00A0🔴\u00A0\u00A0🔴\033[0m"
    echo -e "\033[1m\033[33m⚠️\u00A0\u00A0 Vui lòng xóa '-DPaper.WorkerThreadCount' khỏi lệnh startup để tiếp tục sử dụng server. \u00A0\u00A0⚠️\033[0m"
    exit 1
else
    echo -e "\033[1m\033[32m✅\u00A0\u00A0✅\u00A0\u00A0✅\u00A0\u00A0 Lệnh startup hợp lệ. Tiếp tục khởi động server... \u00A0\u00A0✅\u00A0\u00A0✅\u00A0\u00A0✅\033[0m"
fi

# server.properties
if [ -f "eula.txt" ]; then
    # create server.properties
    touch server.properties
fi

if [ -f "server.properties" ]; then
    # set server-ip to 0.0.0.0
    if grep -q "server-ip=" server.properties; then
        sed -i 's/server-ip=.*/server-ip=0.0.0.0/' server.properties
    else
        echo "server-ip=0.0.0.0" >> server.properties
    fi

    # set server-port to SERVER_PORT
    if grep -q "server-port=" server.properties; then
        sed -i "s/server-port=.*/server-port=${SERVER_PORT}/" server.properties
    else
        echo "server-port=${SERVER_PORT}" >> server.properties
    fi

    # set query.port to SERVER_PORT
    if grep -q "query.port=" server.properties; then
        sed -i "s/query.port=.*/query.port=${SERVER_PORT}/" server.properties
    else
        echo "query.port=${SERVER_PORT}" >> server.properties
    fi

    # set enable-query to true
    if grep -q "enable-query=" server.properties; then
        sed -i 's/enable-query=.*/enable-query=true/' server.properties
    else
        echo "enable-query=true" >> server.properties
    fi
fi


# velocity.toml
if [ -f "velocity.toml" ]; then
	# set bind to 0.0.0.0:SERVER_PORT
	if grep -q "bind" velocity.toml; then
		sed -i "s/bind = .*/bind = \"0.0.0.0:${SERVER_PORT}\"/" velocity.toml
	else
		echo "bind = \"0.0.0.0:${SERVER_PORT}\"" >> velocity.toml
	fi
fi

# config.yml (tiếp)
if [ -f "config.yml" ]; then
    # set query_port to SERVER_PORT
    if grep -q "query_port" config.yml; then
        sed -i "s/query_port: .*/query_port: ${SERVER_PORT}/" config.yml
    else
        echo "query_port: ${SERVER_PORT}" >> config.yml
    fi

    # set host to 0.0.0.0:SERVER_PORT
    if grep -q "host" config.yml; then
        sed -i "s/host: .*/host: 0.0.0.0:${SERVER_PORT}/" config.yml
    else
        echo "host: 0.0.0.0:${SERVER_PORT}" >> config.yml
    fi
fi

if [[ "$OVERRIDE_STARTUP" == "1" ]]; then
    FLAGS=("-XX:+UseContainerSupport")
    # SIMD Operations are only for Java 16 - 21
    if [[ "$SIMD_OPERATIONS" == "1" ]]; then
        if [[ "$JAVA_MAJOR_VERSION" -ge 16 ]] && [[ "$JAVA_MAJOR_VERSION" -le 21 ]]; then
            FLAGS+=("--add-modules=jdk.incubator.vector")
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0 SIMD Operations chỉ khả dụng cho Java 16 - 21, bỏ qua..."
        fi
    fi
    if [[ "$REMOVE_UPDATE_WARNING" == "1" ]]; then
        FLAGS+=("-DIReallyKnowWhatIAmDoingISwear")
    fi
    if [[ -n "$JAVA_AGENT" ]]; then
        if [ -f "$JAVA_AGENT" ]; then
            FLAGS+=("-javaagent:$JAVA_AGENT")
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0 JAVA_AGENT tệp không tồn tại, bỏ qua..."
        fi
    fi
    if [[ "$MINEHUT_SUPPORT" == "Velocity" ]]; then
        FLAGS+=("-Dmojang.sessionserver=https://api.minehut.com/mitm/proxy/session/minecraft/hasJoined")
    elif [[ "$MINEHUT_SUPPORT" == "Waterfall" ]]; then
        FLAGS+=("-Dwaterfall.auth.url=\"https://api.minehut.com/mitm/proxy/session/minecraft/hasJoined?username=%s&serverId=%s%s\")")
    elif [[ "$MINEHUT_SUPPORT" = "Bukkit" ]]; then
        FLAGS+=("-Dminecraft.api.auth.host=https://authserver.mojang.com/ -Dminecraft.api.account.host=https://api.mojang.com/ -Dminecraft.api.services.host=https://api.minecraftservices.com/ -Dminecraft.api.session.host=https://api.minehut.com/mitm/proxy")
    fi

    # Khởi tạo bộ nhớ cho máy chủ
    PARSED="java ${FLAGS[*]} -Xms256M -Xmx$(if [[ -z "$DATE_FORMAT" || "$DATE_FORMAT" -eq 0 ]]; then echo $((SERVER_MEMORY - 1024)); else echo $((DATE_FORMAT - 1024)); fi)M ${SERVER_STARTUP} -jar ${SERVER_JARFILE}"
    
    # Thông báo khi máy chủ bắt đầu khởi động
    printf "\033[1m\033[38;5;208m BUMBOOHOST \033[0m\033[1m\033[33m🛠️\u00A0 MÁY CHỦ ĐANG KHỞI ĐỘNG, VUI LÒNG CHỜ \u00A0🛠️\033[0m\n"
    
    # In ra lệnh mà chúng ta đang chạy
    printf "${LOG_PREFIX} %s\n" "$PARSED"
    
    # Chạy máy chủ
    env ${PARSED}
    
    # Thông báo khi máy chủ đã dừng
    printf "\033[1m\033[32m✅\u00A0 Máy chủ đã dừng thành công. \u00A0✅\033[0m\n"
    printf "\033[1m\033[31m📞\u00A0 Nếu có lỗi xảy ra, vui lòng liên hệ qua Discord hoặc Facebook của BUMBOOHOST để được hỗ trợ. \u00A0📞\033[0m\n"
    printf "\033[1m\033[36mDiscord: https://discord.com/invite/FsCb5uVNZx\033[0m\n"
    printf "\033[1m\033[36mFanpage: https://m.me/100088824591929\033[0m\n"
fi