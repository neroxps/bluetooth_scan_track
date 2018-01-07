#!/bin/bash
#HA_API_PASSWD="homeassis_restapi_password"
#HA_URL="https://homeassistant_url"
#set -x
KOWN_DEVICES_FILE="/known_devices.yaml"
if [[ ! -n $SLEEP_NUM ]]; then
	SLEEP_NUM=2
fi
if [[ ! -n $HA_API_PASSWD ]]; then
	echo 'HA_API_PASSWD为空值，请使用 [-e HA_API_PASSWD="homeassistant_rest_api_passowrd] 设置此值。'
	exit
fi
if [[ ! -n $HA_URL ]]; then
	echo '$HA_URL 为空值，请使用 [-e HA_URL="https://home-assistant_url"] 设置此值。'
	exit
fi
if [[ ! -f $KOWN_DEVICES_FILE ]]; then
	echo "没有找到 $KOWN_DEVICES_FILE, 请使用 [-v /usr/share/hassio/homeassistant/known_devices.yaml:/known_devices.yaml] 映射此目录入容器内"
fi

declare -a DEV_BD_NAME
declare -a DEV_STATUS
declare -a DEV_ID
DEV_ID=($(cat ${KOWN_DEVICES_FILE} | grep -v '^[[:blank:]].*' | grep -v '^$' | grep -v '^#' | cut -d ":" -f1))

function parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml ${KOWN_DEVICES_FILE} "bluetooth_")


function POST_HA(){	
	curl -X POST \
		-H "x-ha-access: ${HA_API_PASSWD}" \
		-H "Content-Type: application/json" \
		-d '{"dev_id":"'"${DEV_ID[${i}]}"'","location_name":"'"${DEV_STATUS[${i}]}"'"}' \
		${HA_URL}/api/services/device_tracker/see > /dev/null 2>&1
}

while true; do
	i=0
	while [[ ${i} -lt ${#DEV_ID[@]} ]]; do
		eval TRACK=\$bluetooth_${DEV_ID[${i}]}_track
		if [[ ${TRACK} == "true" ]]; then
			eval MAC=\$bluetooth_${DEV_ID[${i}]}_mac
			DEV_BD_NAME="$(hcitool name ${MAC})"
			if [[ "${DEV_BD_NAME}" == "" ]]; then
				STATUS="not_home"
				if [[ "${STATUS}" != "${DEV_STATUS[${i}]}" ]]; then
					DEV_STATUS[${i}]=${STATUS}
					POST_HA
				fi
			else
				STATUS="home"
				if [[ "${STATUS}" != "${DEV_STATUS[${i}]}" ]]; then
					DEV_STATUS[${i}]=${STATUS}
					POST_HA
				fi
			fi
			echo "${DEV_ID[${i}]} ${DEV_STATUS[${i}]}"
		fi
		let i++
	done
	sleep ${SLEEP_NUM}
done
