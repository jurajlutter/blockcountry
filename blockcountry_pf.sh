#!/bin/sh

# based on https://mirror.ideaz.sk/Software/SAGEtools/Tools/blockcountry.sh
# WWW: https://github.com/jurajlutter/blockcountry
#comment
# pf table name
readonly TABLENAME="countryblock"

# Directory for storing rules files.
readonly RULEDIR="/var/db/pf-countryblock"

download_zone() {
	local CNT=1
	local ZONEURL=$1
	local FNAME=$2

	while [ ! -s "${FNAME}" ]; do
		rm -f ${FNAME} >/dev/null 2>&1
		case $CNT in
		1)
			echo "Try ${CNT}: fetch https"
			fetch -q -o ${FNAME} ${ZONEURL}
			;;
		2)
			echo "Try ${CNT}: curl https"
			curl -f ${ZONEURL} > ${FNAME} 2>/dev/null
			;;
		3)
			echo "Try ${CNT}: wget https"
			wget -q ${ZONEURL} -O ${FNAME} >/dev/null 2>&1
			;;
		4)
			echo "Try ${CNT}: fetch insecure https"
			fetch -q --no-verify-hostname --no-verify-peer -o ${FNAME} ${ZONEURL}
			;;
		5)
			echo "Try ${CNT}: curl insecure https"
			curl -f --insecure ${ZONEURL} > ${FNAME} 2>/dev/null
			;;
		6)
			echo "Try ${CNT}: wget insecure https"
			wget -q --no-check-certificate ${ZONEURL} -O ${FNAME} >/dev/null 2>&1
			;;
		*)
			rm -f ${FNAME} >/dev/null 2>&1
			break
			;;
		esac
		CNT=$((CNT + 1))
	done
}

download_and_add() {
    local var=$1
    FNAMES="${RULEDIR}/${var}-aggregated.zone ${RULEDIR}/${var}-aggregated6.zone"
    set -- ${FNAMES}
    ZONEURLS="https://www.ipdeny.com/ipblocks/data/aggregated/${var}-aggregated.zone https://www.ipdeny.com/ipv6/ipaddresses/aggregated/${var}-aggregated.zone"
    for ZONEURL in ${ZONEURLS}; do
      FNAME=$1
      shift
      if [ ! -s "${FNAME}" ]; then
          [ -t 1 ] && echo "File '${FNAME}' does not exist. Trying download from '${ZONEURL}'."
          download_zone ${ZONEURL} ${FNAME}
          if [ ! -s "${FNAME}" ]; then
              [ -t 1 ] && echo "Zone for '${var}' not present, skipping..."
              return
          fi
      fi
      [ -t 1 ] && echo "Adding zone '${var}' to blocklist"
      /sbin/pfctl -q -Tadd -t ${TABLENAME} -f ${FNAME}
    done
}

usage() {
	cat <<EEOOMM
Usage:

1) Adjust TABLENAME and/or RULEDIR atop of this script

2) Add following or similar rules to /etc/pf.conf:

    table <countryblock> persist
    block quick log on em0 from <countryblock> to any

3) Reload the pf configuration

    /etc/rc.d/pf reload

4) Load the apropriate blocking zones. Example:

    blockcountry_pf.sh by cn ru

5) Optionally, activate this script in crontab. Example for /etc/crontab, each day on 1:00:

0	1	*	*	*	root	/usr/local/sbin/blockcountry_pf.sh > /dev/null 2&1

EEOOMM
	exit 1
}

[ $# -lt 1 ] && [ -t 1 ] && usage

if [ ! -d "${RULEDIR}" ]; then
	mkdir -p ${RULEDIR}
	if [ ! -d "${RULEDIR}" ]; then
		[ -t 1 ] && echo "Unable to create directory ${RULEDIR}! Blocking will not work"
		exit 1
	fi
fi

for var in "$@"; do
    download_and_add "${var}"
done

exit 0
