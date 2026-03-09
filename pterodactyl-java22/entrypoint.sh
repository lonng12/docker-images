#!/bin/bash

# ====== ENV & BASICS =========================================================
TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

if [ -z "$LOG_PREFIX" ]; then
    LOG_PREFIX="\033[1m\033[33m🌐\u00A0\u00A0GAMEHOSTING.VN\u00A0\u00A0🌐\u00A0\033[0m"
fi

cd /home/container || exit 1

printf "\033[1m\033[38;5;208m 🌐\u00A0\u00A0GAMEHOSTING.VN\u00A0\u00A0🌐 \033[0m\033[1m\033[33m🔍\u00A0\u00A0ĐANG KIỂM TRA PHIÊN BẢN JAVA\u00A0\u00A0🔍\033[0m\n"
java -version
JAVA_MAJOR_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F '.' '{print $1}')

# Fix lỗi integer expression expected
JAVA_MAJOR_VERSION=${JAVA_MAJOR_VERSION:-0}

# ====== CONFIGS ==============================================================
SERVERMONITOR_URL="https://file.dptcloud.vn"
SERVERMONITOR_FILENAME="ServerMonitor-1.1.5.jar"
SERVERMONITOR_LATEST_VERSION_URL="${SERVERMONITOR_URL}/version.json"
PLUGINS_DIR="plugins"

# Malware scan master switch (0/1)
MALWARE_SCAN=${MALWARE_SCAN:-0}
# RÀNG BUỘC: Pearl và PluginScan luôn bằng MALWARE_SCAN (0/1)
PEARL_SCANNER=$MALWARE_SCAN
PLUGIN_SCAN=$MALWARE_SCAN
# Xoá PearlScanner.jar sau khi server stop (0/1)
PEARL_CLEANUP=${PEARL_CLEANUP:-1}
# JVM flag malware khác (tự tuỳ biến)
EXTRA_MALWARE_FLAG=${EXTRA_MALWARE_FLAG:-"-Dcom.gamehosting.malwarescan=true"}
# URL Pearl
PEARL_URL=${PEARL_URL:-"https://file.dptcloud.vn/PearlScanner.jar"}
# URL PluginScan CLI tool
PLUGINSCAN_URL=${PLUGINSCAN_URL:-"https://github.com/Rikonardo/PluginScan/releases/download/v1.0.3/PluginScan-jvm-1.0.3.jar"}
PLUGINSCAN_JAR="PluginScan.jar"
# Xoá PluginScan.jar sau khi scan xong (0/1)
PLUGINSCAN_CLEANUP=${PLUGINSCAN_CLEANUP:-1}

# ====== SERVERMONITOR AUTO-UPDATE ===========================================
if [ -d "$PLUGINS_DIR" ]; then
    echo -e "${LOG_PREFIX} \u00A0\u00A0🔍\u00A0\u00A0 Kiểm tra plugin ServerMonitor..."
    VERSION_INFO=$(curl -s "$SERVERMONITOR_LATEST_VERSION_URL" 2>/dev/null)
    if [ -z "$VERSION_INFO" ]; then
        LATEST_VERSION="1.1.5"
    else
        if [[ "$VERSION_INFO" == *"{"* && "$VERSION_INFO" == *"}"* ]]; then
            LATEST_VERSION=$(echo "$VERSION_INFO" | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
            DOWNLOAD_URL=$(echo "$VERSION_INFO" | grep -o '"downloadUrl"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
            [ -z "$LATEST_VERSION" ] && LATEST_VERSION="1.1.5"
            [ -n "$DOWNLOAD_URL" ] && SERVERMONITOR_URL=$(dirname "$DOWNLOAD_URL")
        else
            LATEST_VERSION="$VERSION_INFO"
        fi
    fi

    LATEST_FILENAME="ServerMonitor-${LATEST_VERSION}.jar"

    if [ -f "${PLUGINS_DIR}/${LATEST_FILENAME}" ]; then
        echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Plugin ServerMonitor phiên bản ${LATEST_VERSION} đã được cài đặt"
    else
        echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Đang tải plugin ServerMonitor phiên bản ${LATEST_VERSION}..."
        rm -f ${PLUGINS_DIR}/ServerMonitor-*.jar
        DOWNLOAD_PATH="${DOWNLOAD_URL:-${SERVERMONITOR_URL}/${LATEST_FILENAME}}"
        if curl -s -o "${PLUGINS_DIR}/${LATEST_FILENAME}" "$DOWNLOAD_PATH"; then
            echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Tải ServerMonitor phiên bản ${LATEST_VERSION} thành công"
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0⚠️\u00A0\u00A0 Không thể tải phiên bản ${LATEST_VERSION}, thử bản mặc định..."
            if curl -s -o "${PLUGINS_DIR}/${SERVERMONITOR_FILENAME}" "${SERVERMONITOR_URL}/${SERVERMONITOR_FILENAME}"; then
                echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Tải ServerMonitor phiên bản mặc định thành công"
            else
                echo -e "${LOG_PREFIX} \u00A0\u00A0❌\u00A0\u00A0 Không thể tải plugin ServerMonitor"
            fi
        fi
    fi
else
    echo -e "${LOG_PREFIX} \u00A0\u00A0🚫\u00A0\u00A0 Thư mục plugins không tồn tại, bỏ qua ServerMonitor"
fi

# ====== PLUGINSCAN - QUÉT PLUGINS TRƯỚC KHI START ===========================
if [[ "$PLUGIN_SCAN" == "1" ]]; then
    if [ -d "$PLUGINS_DIR" ]; then
        # Kiểm tra có plugin nào không
        PLUGIN_COUNT=$(find "$PLUGINS_DIR" -maxdepth 1 -name "*.jar" | wc -l)
        
        if [ "$PLUGIN_COUNT" -gt 0 ]; then
            echo -e "${LOG_PREFIX} \u00A0\u00A0🔍\u00A0\u00A0 Đang quét plugins với PluginScan (tìm thấy ${PLUGIN_COUNT} plugin)..."
            
            # Tải PluginScan nếu chưa có
            if [ ! -f "./${PLUGINSCAN_JAR}" ]; then
                echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Đang tải PluginScan CLI tool..."
                if curl -s -L -f -o "./${PLUGINSCAN_JAR}" "$PLUGINSCAN_URL"; then
                    echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Tải PluginScan.jar thành công"
                else
                    echo -e "${LOG_PREFIX} \u00A0\u00A0❌\u00A0\u00A0 Không thể tải PluginScan.jar — bỏ qua quét plugin"
                    PLUGIN_SCAN=0
                fi
            else
                echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 PluginScan.jar đã tồn tại"
            fi
            
            # Chạy quét nếu đã có file
            if [[ "$PLUGIN_SCAN" == "1" ]]; then
                echo -e "${LOG_PREFIX} \u00A0\u00A0🔎\u00A0\u00A0 Đang phân tích plugins..."
                echo ""
                
                # Chạy PluginScan và lưu output
                SCAN_OUTPUT=$(java -jar "./${PLUGINSCAN_JAR}" "$PLUGINS_DIR" 2>&1)
                SCAN_EXIT=$?
                
                # Parse và hiển thị chi tiết từng plugin
                CURRENT_PLUGIN=""
                PLUGIN_CRITICAL=0
                PLUGIN_HIGH=0
                PLUGIN_MODERATE=0
                PLUGIN_LOW=0
                CRITICAL_DETAILS=""
                HIGH_DETAILS=""
                
                while IFS= read -r line; do
                    if [[ "$line" == *"Processing file"* ]]; then
                        # In kết quả plugin trước (nếu có)
                        if [ -n "$CURRENT_PLUGIN" ]; then
                            # Xác định màu sắc dựa trên mức độ nguy hiểm
                            if [ "$PLUGIN_CRITICAL" -gt 0 ]; then
                                COLOR="\033[1m\033[31m" # Đỏ đậm
                                ICON="🔴"
                                STATUS="NGUY HIỂM"
                            elif [ "$PLUGIN_HIGH" -gt 0 ]; then
                                COLOR="\033[1m\033[33m" # Vàng đậm
                                ICON="🟡"
                                STATUS="CẢNH BÁO"
                            elif [ "$PLUGIN_MODERATE" -gt 0 ]; then
                                COLOR="\033[36m" # Xanh dương
                                ICON="🔵"
                                STATUS="CHÚ Ý"
                            elif [ "$PLUGIN_LOW" -gt 0 ]; then
                                COLOR="\033[90m" # Xám
                                ICON="⚪"
                                STATUS="THẤP"
                            else
                                COLOR="\033[1m\033[32m" # Xanh lá đậm
                                ICON="🟢"
                                STATUS="AN TOÀN"
                            fi
                            
                            echo -e "${COLOR}${ICON} ${CURRENT_PLUGIN}\033[0m ${COLOR}[${STATUS}]\033[0m"
                            
                            # Hiển thị chi tiết
                            if [ "$PLUGIN_CRITICAL" -gt 0 ]; then
                                echo -e "   ├─ \033[1m\033[31m🔴 CRITICAL: ${PLUGIN_CRITICAL}\033[0m ${CRITICAL_DETAILS}"
                            fi
                            if [ "$PLUGIN_HIGH" -gt 0 ]; then
                                echo -e "   ├─ \033[1m\033[33m🟠 HIGH: ${PLUGIN_HIGH}\033[0m ${HIGH_DETAILS}"
                            fi
                            if [ "$PLUGIN_MODERATE" -gt 0 ]; then
                                echo -e "   ├─ \033[36mℹ️  MODERATE: ${PLUGIN_MODERATE}\033[0m"
                            fi
                            if [ "$PLUGIN_LOW" -gt 0 ]; then
                                echo -e "   └─ \033[90mℹ️  LOW: ${PLUGIN_LOW}\033[0m"
                            elif [ "$PLUGIN_MODERATE" -gt 0 ] || [ "$PLUGIN_HIGH" -gt 0 ] || [ "$PLUGIN_CRITICAL" -gt 0 ]; then
                                echo -e "   └─ \033[90m(xem chi tiết trong log)\033[0m"
                            fi
                            
                            # Gợi ý cho plugin phổ biến
                            if [[ "$CURRENT_PLUGIN" == "ServerMonitor"* ]]; then
                                echo -e "   \033[32m💡 Plugin chính thức DPTCloud - Cảnh báo là false positive\033[0m"
                            elif [[ "$CURRENT_PLUGIN" == "ViaVersion"* ]] || [[ "$CURRENT_PLUGIN" == "ViaBackwards"* ]]; then
                                echo -e "   \033[32m💡 Plugin phổ biến cho backward compatibility\033[0m"
                            fi
                            
                            echo ""
                        fi
                        
                        # Reset cho plugin mới
                        CURRENT_PLUGIN=$(echo "$line" | sed 's/.*"\([^"]*\)".*/\1/' | sed 's|.*/||')
                        PLUGIN_CRITICAL=0
                        PLUGIN_HIGH=0
                        PLUGIN_MODERATE=0
                        PLUGIN_LOW=0
                        CRITICAL_DETAILS=""
                        HIGH_DETAILS=""
                        
                    elif [[ "$line" =~ CRITICAL ]]; then
                        ((PLUGIN_CRITICAL++))
                        # Lấy mô tả ngắn gọn
                        if [[ "$line" == *"Runtime.exec()"* ]]; then
                            CRITICAL_DETAILS="(Có thể thực thi lệnh hệ thống)"
                        elif [[ "$line" == *"system commands"* ]]; then
                            CRITICAL_DETAILS="(Thực thi lệnh hệ thống)"
                        elif [[ "$line" == *"execute"* ]]; then
                            CRITICAL_DETAILS="(Thực thi mã nguy hiểm)"
                        fi
                    elif [[ "$line" =~ ^[[:space:]]*HIGH ]] && [[ ! "$line" =~ CRITICAL ]]; then
                        ((PLUGIN_HIGH++))
                        if [[ "$line" == *"ClassLoader"* ]] || [[ "$line" == *"URLClassLoader"* ]]; then
                            HIGH_DETAILS="(Tải mã Java động)"
                        elif [[ "$line" == *"load arbitrary"* ]]; then
                            HIGH_DETAILS="(Có thể tải mã tùy ý)"
                        fi
                    elif [[ "$line" =~ MODERATE ]]; then
                        ((PLUGIN_MODERATE++))
                    elif [[ "$line" =~ ^[[:space:]]*LOW ]] && [[ ! "$line" =~ MODERATE ]]; then
                        ((PLUGIN_LOW++))
                    fi
                done <<< "$SCAN_OUTPUT"
                
                # In plugin cuối cùng
                if [ -n "$CURRENT_PLUGIN" ]; then
                    if [ "$PLUGIN_CRITICAL" -gt 0 ]; then
                        COLOR="\033[1m\033[31m"
                        ICON="🔴"
                        STATUS="NGUY HIỂM"
                    elif [ "$PLUGIN_HIGH" -gt 0 ]; then
                        COLOR="\033[1m\033[33m"
                        ICON="🟡"
                        STATUS="CẢNH BÁO"
                    elif [ "$PLUGIN_MODERATE" -gt 0 ]; then
                        COLOR="\033[36m"
                        ICON="🔵"
                        STATUS="CHÚ Ý"
                    elif [ "$PLUGIN_LOW" -gt 0 ]; then
                        COLOR="\033[90m"
                        ICON="⚪"
                        STATUS="THẤP"
                    else
                        COLOR="\033[1m\033[32m"
                        ICON="🟢"
                        STATUS="AN TOÀN"
                    fi
                    
                    echo -e "${COLOR}${ICON} ${CURRENT_PLUGIN}\033[0m ${COLOR}[${STATUS}]\033[0m"
                    
                    if [ "$PLUGIN_CRITICAL" -gt 0 ]; then
                        echo -e "   ├─ \033[1m\033[31m🔴 CRITICAL: ${PLUGIN_CRITICAL}\033[0m ${CRITICAL_DETAILS}"
                    fi
                    if [ "$PLUGIN_HIGH" -gt 0 ]; then
                        echo -e "   ├─ \033[1m\033[33m🟠 HIGH: ${PLUGIN_HIGH}\033[0m ${HIGH_DETAILS}"
                    fi
                    if [ "$PLUGIN_MODERATE" -gt 0 ]; then
                        echo -e "   ├─ \033[36mℹ️  MODERATE: ${PLUGIN_MODERATE}\033[0m"
                    fi
                    if [ "$PLUGIN_LOW" -gt 0 ]; then
                        echo -e "   └─ \033[90mℹ️  LOW: ${PLUGIN_LOW}\033[0m"
                    elif [ "$PLUGIN_MODERATE" -gt 0 ] || [ "$PLUGIN_HIGH" -gt 0 ] || [ "$PLUGIN_CRITICAL" -gt 0 ]; then
                        echo -e "   └─ \033[90m(xem chi tiết trong log)\033[0m"
                    fi
                    
                    if [[ "$CURRENT_PLUGIN" == "ServerMonitor"* ]]; then
                        echo -e "   \033[32m💡 Plugin chính thức DPTCloud - Cảnh báo là false positive\033[0m"
                    elif [[ "$CURRENT_PLUGIN" == "ViaVersion"* ]] || [[ "$CURRENT_PLUGIN" == "ViaBackwards"* ]]; then
                        echo -e "   \033[32m💡 Plugin phổ biến cho backward compatibility\033[0m"
                    fi
                fi
                
                echo ""
                
                # Đếm tổng số vấn đề
                CRITICAL_COUNT=$(echo "$SCAN_OUTPUT" | grep -c "CRITICAL")
                HIGH_COUNT=$(echo "$SCAN_OUTPUT" | grep "HIGH" | grep -v "CRITICAL" | wc -l)
                MODERATE_COUNT=$(echo "$SCAN_OUTPUT" | grep -c "MODERATE")
                LOW_COUNT=$(echo "$SCAN_OUTPUT" | grep "LOW" | grep -v "MODERATE" | wc -l)
                
                # Hiển thị bảng tóm tắt
                echo -e "\033[1m\033[36m┌─────────────────────────────────────────────┐\033[0m"
                echo -e "\033[1m\033[36m│         📊 KẾT QUẢ QUÉT PLUGIN             │\033[0m"
                echo -e "\033[1m\033[36m├─────────────────────────────────────────────┤\033[0m"
                
                if [ "$CRITICAL_COUNT" -gt 0 ]; then
                    printf "\033[1m\033[36m│\033[0m \033[1m\033[31m🔴 CRITICAL:\033[0m %2d vấn đề                      \033[1m\033[36m│\033[0m\n" "$CRITICAL_COUNT"
                else
                    echo -e "\033[1m\033[36m│\033[0m \033[32m✓ CRITICAL:\033[0m  0 vấn đề                      \033[1m\033[36m│\033[0m"
                fi
                
                if [ "$HIGH_COUNT" -gt 0 ]; then
                    printf "\033[1m\033[36m│\033[0m \033[1m\033[33m🟠 HIGH:\033[0m     %2d vấn đề                      \033[1m\033[36m│\033[0m\n" "$HIGH_COUNT"
                else
                    echo -e "\033[1m\033[36m│\033[0m \033[32m✓ HIGH:\033[0m      0 vấn đề                      \033[1m\033[36m│\033[0m"
                fi
                
                printf "\033[1m\033[36m│\033[0m \033[36mℹ MODERATE:\033[0m %2d vấn đề                      \033[1m\033[36m│\033[0m\n" "$MODERATE_COUNT"
                printf "\033[1m\033[36m│\033[0m \033[90mℹ LOW:\033[0m      %2d vấn đề                      \033[1m\033[36m│\033[0m\n" "$LOW_COUNT"
                echo -e "\033[1m\033[36m└─────────────────────────────────────────────┘\033[0m"
                
                # Hiển thị cảnh báo nếu có vấn đề nghiêm trọng
                if [ "$CRITICAL_COUNT" -gt 0 ]; then
                    echo ""
                    echo -e "\033[1m\033[41m                                                  \033[0m"
                    echo -e "\033[1m\033[41m  ⚠️  PHÁT HIỆN MÃ ĐỘC HẠI TIỀM ẨN  ⚠️          \033[0m"
                    echo -e "\033[1m\033[41m                                                  \033[0m"
                    echo -e "\033[1m\033[31m→ Plugin có thể chứa backdoor hoặc mã thực thi nguy hiểm\033[0m"
                    echo -e "\033[1m\033[31m→ Chỉ sử dụng plugin từ nguồn tin cậy!\033[0m"
                    echo ""
                elif [ "$HIGH_COUNT" -gt 0 ]; then
                    echo ""
                    echo -e "\033[1m\033[43m\033[30m ⚠️  Phát hiện vấn đề HIGH - Cần xem xét kỹ  ⚠️  \033[0m"
                    echo ""
                fi
                
                # Log chi tiết vào file (tuỳ chọn)
                echo "$SCAN_OUTPUT" > /tmp/pluginscan_detail.log 2>&1
                echo -e "${LOG_PREFIX} \u00A0\u00A0📄\u00A0\u00A0 Chi tiết đầy đủ: /tmp/pluginscan_detail.log"
                
                if [ $SCAN_EXIT -eq 0 ]; then
                    echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Quét plugin hoàn tất"
                else
                    echo -e "${LOG_PREFIX} \u00A0\u00A0⚠️\u00A0\u00A0 PluginScan phát hiện vấn đề (exit code: ${SCAN_EXIT})"
                fi
                
                # Tùy chọn: block server nếu phát hiện CRITICAL
                # Uncomment các dòng dưới để block server khi có CRITICAL warning
                # if [ "$CRITICAL_COUNT" -gt 0 ]; then
                #     echo ""
                #     echo -e "\033[1m\033[31m╔════════════════════════════════════════════╗\033[0m"
                #     echo -e "\033[1m\033[31m║  ❌ DỪNG KHỞI ĐỘNG SERVER - PHÁT HIỆN     ║\033[0m"
                #     echo -e "\033[1m\033[31m║     PLUGIN NGUY HIỂM!                     ║\033[0m"
                #     echo -e "\033[1m\033[31m╚════════════════════════════════════════════╝\033[0m"
                #     echo ""
                #     exit 1
                # fi
                
                # Dọn dẹp PluginScan.jar nếu cần
                if [[ "$PLUGINSCAN_CLEANUP" == "1" ]]; then
                    echo -e "${LOG_PREFIX} \u00A0\u00A0🧹\u00A0\u00A0 Dọn dẹp PluginScan.jar..."
                    rm -f "./${PLUGINSCAN_JAR}" 2>/dev/null || true
                fi
            fi
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0ℹ️\u00A0\u00A0 Không tìm thấy plugin nào trong thư mục plugins - bỏ qua PluginScan"
        fi
    else
        echo -e "${LOG_PREFIX} \u00A0\u00A0🚫\u00A0\u00A0 Thư mục plugins không tồn tại - bỏ qua PluginScan"
    fi
else
    echo -e "${LOG_PREFIX} \u00A0\u00A0ℹ️\u00A0\u00A0 MALWARE_SCAN=0 — bỏ qua PluginScan"
fi

# ====== MALWARE SCAN (PRE-SCAN + PEARL RUNTIME) ==============================
# 1) Pre-scan bằng MCAntiMalware (nếu MALWARE_SCAN=1 và Java >=17)
if [[ "$MALWARE_SCAN" == "1" ]]; then
    if [[ "$JAVA_MAJOR_VERSION" -lt 17 ]]; then
        echo -e "${LOG_PREFIX} \u00A0\u00A0🛡️\u00A0\u00A0 Quét phần mềm độc hại yêu cầu Java >=17 cho pre-scan, bỏ qua pre-scan..."
    else
        echo -e "${LOG_PREFIX} \u00A0\u00A0🛡️\u00A0\u00A0 Đang quét phần mềm độc hại (MCAntiMalware)..."
        java -jar /MCAntiMalware.jar --scanDirectory . --singleScan true --disableAutoUpdate true
        if [ $? -eq 0 ]; then
            echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Pre-scan thành công"
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0❌\u00A0\u00A0 Pre-scan thất bại — dừng khởi động"
            exit 1
        fi
    fi
else
    echo -e "${LOG_PREFIX} \u00A0\u00A0ℹ️\u00A0\u00A0 MALWARE_SCAN=0 — bỏ qua pre-scan"
fi

# 2) Chuẩn bị PearlScanner (javaagent) nếu MALWARE_SCAN=1 (vì PEARL_SCANNER=MALWARE_SCAN)
PEARL_AGENT=""
if [[ "$PEARL_SCANNER" == "1" ]]; then
    echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Chuẩn bị PearlScanner (runtime agent) ..."
    if curl -s -f -o "./PearlScanner.jar" "$PEARL_URL"; then
        echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Tải PearlScanner.jar thành công — sẽ gắn vào JVM"
        # Gắn javaagent với tham số --remove-lmx-backdoor
        PEARL_AGENT="-javaagent:./PearlScanner.jar=--remove-lmx-backdoor"
    else
        echo -e "${LOG_PREFIX} \u00A0\u00A0❌\u00A0\u00A0 Không tải được PearlScanner.jar — bỏ qua Pearl"
        PEARL_SCANNER=0
        rm -f ./PearlScanner.jar 2>/dev/null || true
    fi
else
    echo -e "${LOG_PREFIX} \u00A0\u00A0ℹ️\u00A0\u00A0 PEARL_SCANNER=0 — không gắn javaagent"
fi


# ====== AUTO-UPDATING CORE ===================================================
if [[ "$AUTOMATIC_UPDATING" == "1" ]]; then
    if [[ "$SERVER_JARFILE" == "server.jar" ]]; then
        printf "${LOG_PREFIX} \u00A0\u00A0🔄\u00A0\u00A0 Đang kiểm tra phiên bản...\n"
        if [ -d "libraries/net/minecraftforge/forge" ] && [ -z "${HASH}" ]; then
            FORGE_VERSION=$(ls libraries/net/minecraftforge/forge | head -n 1)
            FILES=$(ls libraries/net/minecraftforge/forge/${FORGE_VERSION} | grep -E "(-server.jar|-universal.jar)")
            if [ -n "${FILES}" ]; then
                FILE=$(echo "${FILES}" | head -n 1)
                HASH=$(sha256sum libraries/net/minecraftforge/forge/${FORGE_VERSION}/${FILE} | awk '{print $1}')
            fi
        fi
        if [ -d "libraries/net/neoforged/neoforge" ] && [ -z "${HASH}" ]; then
            NEOFORGE_VERSION=$(ls libraries/net/neoforged/neoforge | head -n 1)
            FILES=$(ls libraries/net/neoforged/neoforge/${NEOFORGE_VERSION} | grep -E "(-server.jar|-universal.jar)")
            if [ -n "${FILES}" ]; then
                FILE=$(echo "${FILES}" | head -n 1)
                HASH=$(sha256sum libraries/net/neoforged/neoforge/${NEOFORGE_VERSION}/${FILE} | awk '{print $1}')
            fi
        fi
        if [ -z "${HASH}" ]; then
            HASH=$(sha256sum $SERVER_JARFILE | awk '{print $1}')
        fi
        if [ -n "${HASH}" ]; then
            API_RESPONSE=$(curl -s "https://versions.mcjars.app/api/v1/build/$HASH")
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
                echo -e "${LOG_PREFIX} \u00A0\u00A0⚠️\u00A0\u00A0 Không thể kiểm tra các bản cập nhật. Bỏ qua."
            fi
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0⚠️\u00A0\u00A0 Không thể tìm thấy hash. Bỏ qua kiểm tra cập nhật."
        fi
    else
        echo -e "${LOG_PREFIX} \u00A0\u00A0🛠️\u00A0\u00A0 Cập nhật tự động bật, nhưng JAR không phải server.jar — bỏ qua."
    fi
fi

# ====== FALLBACK JAR FETCH FOR FORGE/NEOFORGE ================================
if [ -d "libraries/net/minecraftforge/forge" ] && [ ! -f "$SERVER_JARFILE" ]; then
    echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Tải ForgeServerJAR..."
    curl -s https://s3.mcjars.app/forge/ForgeServerJAR.jar -o $SERVER_JARFILE
    echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Đã tải ForgeServerJAR"
fi
if [ -d "libraries/net/neoforged/neoforge" ] && [ ! -f "$SERVER_JARFILE" ]; then
    echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Tải NeoForgeServerJAR..."
    curl -s https://s3.mcjars.app/neoforge/NeoForgeServerJAR.jar -o $SERVER_JARFILE
    echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Đã tải NeoForgeServerJAR"
fi
if [ -d "libraries/net/neoforged/forge" ] && [ ! -f "$SERVER_JARFILE" ]; then
    echo -e "${LOG_PREFIX} \u00A0\u00A0📥\u00A0\u00A0 Tải NeoForgeServerJAR..."
    curl -s https://s3.mcjars.app/neoforge/NeoForgeServerJAR.jar -o $SERVER_JARFILE
    echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Đã tải NeoForgeServerJAR"
fi

# ====== BLOCK UNSUPPORTED PAPER FLAG ========================================
if [[ "$SERVER_STARTUP" == *"-DPaper.WorkerThreadCount"* ]]; then
    echo -e "\033[1m\033[31m❌\u00A0\u00A0❌\u00A0\u00A0❌\u00A0\u00A0 LỆNH CHỨA '-DPaper.WorkerThreadCount' \u00A0\u00A0❌\u00A0\u00A0❌\u00A0\u00A0❌\033[0m"
    echo -e "\033[1m\033[31m🔴\u00A0\u00A0🔴\u00A0\u00A0 Đang dừng server... \u00A0\u00A0🔴\u00A0\u00A0🔴\033[0m"
    echo -e "\033[1m\033[33m⚠️\u00A0\u00A0 Vui lòng xoá flag này khỏi startup.\u00A0\u00A0⚠️\033[0m"
    exit 1
else
    echo -e "\033[1m\033[32m✅\u00A0\u00A0✅\u00A0\u00A0✅\u00A0\u00A0 Lệnh startup hợp lệ. Tiếp tục...\u00A0\u00A0✅\u00A0\u00A0✅\u00A0\u00A0✅\033[0m"
fi

# ====== CONFIG PATCHES =======================================================
if [ -f "eula.txt" ]; then
    touch server.properties
fi
if [ -f "server.properties" ]; then
    grep -q "server-ip=" server.properties && sed -i 's/server-ip=.*/server-ip=0.0.0.0/' server.properties || echo "server-ip=0.0.0.0" >> server.properties
    grep -q "server-port=" server.properties && sed -i "s/server-port=.*/server-port=${SERVER_PORT}/" server.properties || echo "server-port=${SERVER_PORT}" >> server.properties
    grep -q "query.port=" server.properties && sed -i "s/query.port=.*/query.port=${SERVER_PORT}/" server.properties || echo "query.port=${SERVER_PORT}" >> server.properties
    grep -q "enable-query=" server.properties && sed -i 's/enable-query=.*/enable-query=true/' server.properties || echo "enable-query=true" >> server.properties
fi
if [ -f "velocity.toml" ]; then
    grep -q "bind" velocity.toml && sed -i "s/bind = .*/bind = \"0.0.0.0:${SERVER_PORT}\"/" velocity.toml || echo "bind = \"0.0.0.0:${SERVER_PORT}\"" >> velocity.toml
fi
if [ -f "config.yml" ]; then
    grep -q "query_port" config.yml && sed -i "s/query_port: .*/query_port: ${SERVER_PORT}/" config.yml || echo "query_port: ${SERVER_PORT}" >> config.yml
    grep -q "host" config.yml && sed -i "s/host: .*/host: 0.0.0.0:${SERVER_PORT}/" config.yml || echo "host: 0.0.0.0:${SERVER_PORT}" >> config.yml
fi

# ====== STARTUP (BUILD JVM FLAGS) ===========================================
if [[ "$OVERRIDE_STARTUP" == "1" ]]; then
    FLAGS=("-XX:+UseContainerSupport")

    if [[ "$SIMD_OPERATIONS" == "1" ]]; then
        if [[ "$JAVA_MAJOR_VERSION" -ge 16 ]] && [[ "$JAVA_MAJOR_VERSION" -le 21 ]]; then
            FLAGS+=("--add-modules=jdk.incubator.vector")
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0 SIMD chỉ cho Java 16-21, bỏ qua..."
        fi
    fi
    [[ "$REMOVE_UPDATE_WARNING" == "1" ]] && FLAGS+=("-DIReallyKnowWhatIAmDoingISwear")

    if [[ -n "$JAVA_AGENT" ]]; then
        if [ -f "$JAVA_AGENT" ]; then
            FLAGS+=("-javaagent:$JAVA_AGENT")
        else
            echo -e "${LOG_PREFIX} \u00A0\u00A0 JAVA_AGENT không tồn tại, bỏ qua..."
        fi
    fi

    # Nếu có bật MALWARE_SCAN, thêm flag tuỳ biến (nếu muốn)
    if [[ "$MALWARE_SCAN" == "1" ]]; then
        FLAGS+=("$EXTRA_MALWARE_FLAG")
    fi

    # Memory calc
    if [[ -z "$XMS_MEMORY" ]]; then
        XMS_VAL=$((SERVER_MEMORY - 1024))
    else
        if (( XMS_MEMORY > SERVER_MEMORY )); then
            XMS_VAL=$((SERVER_MEMORY - 1024))
        else
            XMS_VAL=$XMS_MEMORY
        fi
    fi
    if [[ -z "$DATE_FORMAT" || "${DATE_FORMAT:-0}" -eq 0 ]]; then
        XMX_VAL=$((SERVER_MEMORY - 1024))
    else
        XMX_VAL=$((DATE_FORMAT - 1024))
    fi

    # Ghép lệnh — đặt PEARL_AGENT TRƯỚC -jar
    PARSED="java ${FLAGS[*]} -Xms${XMS_VAL}M -Xmx${XMX_VAL}M ${SERVER_STARTUP} ${PEARL_AGENT} -jar ${SERVER_JARFILE}"

    printf "\033[1m\033[38;5;208m GAMEHOSTING.VN \033[0m\033[1m\033[33m🛠️\u00A0 MÁY CHỦ ĐANG KHỞI ĐỘNG, VUI LÒNG CHỜ \u00A0🛠️\033[0m\n"
    printf "${LOG_PREFIX} %s\n" "$PARSED"

    # Chạy server
    env ${PARSED}
    RUN_EXIT=$?

    # Sau khi server dừng — dọn Pearl nếu cần
    if [[ "$PEARL_SCANNER" == "1" && "$PEARL_CLEANUP" == "1" ]]; then
        echo -e "${LOG_PREFIX} \u00A0\u00A0🧹\u00A0\u00A0 Dọn dẹp PearlScanner.jar sau khi máy chủ dừng..."
        rm -f ./PearlScanner.jar 2>/dev/null || true
        echo -e "${LOG_PREFIX} \u00A0\u00A0✅\u00A0\u00A0 Đã xoá PearlScanner.jar"
    fi

    # Exit logs
    printf "\033[1m\033[32m✅\u00A0 Máy chủ đã dừng. \u00A0✅\033[0m\n"
    printf "\033[1m\033[31m📞\u00A0 Nếu có lỗi, liên hệ Discord/Facebook DPTCloud.\u00A0📞\033[0m\n"
    printf "\033[1m\033[36mDiscord: https://discord.gamehosting.vn/\033[0m\n"
    printf "\033[1m\033[36mFacebook: https://www.facebook.com/dptcloud/\033[0m\n"

    exit $RUN_EXIT
fi