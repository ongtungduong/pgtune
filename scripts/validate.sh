#!/bin/bash

# Validate arguments
if [ -z "$RAM" ]; then
    echo "No RAM specified. Specify the amount of RAM in GB"
    exit 1
fi

if [ -z "$TYPE" ]; then
    echo "No database type specified. Specify the database type (web, oltp, dw, desktop, mixed)"
    exit 1
fi

if [ -z "$CPU" ]; then
    echo "No CPU specified."
fi

if [ -z "$HARD_DRIVE" ]; then
    echo "No hard drive specified. Using SSD."
    HARD_DRIVE="ssd"
fi

if [ -z "$CONNECTIONS" ]; then
    case "$TYPE" in
        web) MAX_CONNECTIONS=200
        ;;
        oltp) MAX_CONNECTIONS=300
        ;;
        dw) MAX_CONNECTIONS=40
        ;;
        desktop) MAX_CONNECTIONS=20
        ;;
        mixed) MAX_CONNECTIONS=100
        ;;
    esac
    echo "No connections specified. Using $MAX_CONNECTIONS."
else
    MAX_CONNECTIONS=$CONNECTIONS
fi

# cat <<- EOF

# Type: $TYPE
# Hard drive: $HARD_DRIVE
# Connections: ${CONNECTIONS:-$MAX_CONNECTIONS}
# RAM: $RAM GB
# EOF

# if [ -n "$CPU" ]; then
#     echo "CPU: $CPU"
# fi
