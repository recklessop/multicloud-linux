#!/bin/bash
SERIAL=`dmidecode -s system-serial-number`
BOARDSERIAL=`dmidecode -s baseboard-serial-number`
ASSETTAG=`dmidecode -s chassis-asset-tag`

if [ "$SYSSERIAL" = "$BOARDSERIAL" ] && [ "$SYSSERIAL" = "$ASSETTAG" ]; then
    echo "System Is Hyper-V"
    exit 0
else
    echo "System Not Hyper-V"
    exit 1
fi
