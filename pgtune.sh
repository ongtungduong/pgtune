#!/bin/bash

script=$(basename "$0")

# Display Help
function help {
    echo 
    echo "Description: PgTune"
    echo "Syntax: $script [-c|-r|-t|-k|-d|-o|help]"
    echo "Example: $script -c 4 -r 16 -t mixed -k 600 -d ssd -o sql"
    echo "Options:"
    echo "  -c    number of CPU cores - Example: 4"
    echo "  -r    RAM size in GB - Example: 16 - (required)"
    echo "  -t    type of database - Options: web, oltp, dw, desktop, mixed - (required)"
    echo "  -k    number of connections - Example: 600"
    echo "  -d    type of hard drive - Options: ssd, hdd - (default: ssd)"
    echo "  -o    output format - Options: conf, sql - (default: conf)"
    echo
}

# Show help and exit
if [[ $1 == 'help' ]]; then
    help
    exit
fi

# Process params
while getopts ":c: :r: :t: :k: :d: :o:" opt; do
    case $opt in
        c) CPU="$OPTARG"
        ;;
        r) RAM="$OPTARG"
        ;;
        t) TYPE="$OPTARG"
        ;;
        k) CONNECTIONS="$OPTARG"
        ;;
        d) HARD_DRIVE="$OPTARG"
        ;;
        o) OUTPUT="$OPTARG"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
        help
        exit;;
    esac
done

# Validate arguments
if [ -z "$RAM" ]; then
    echo "No RAM specified. Specify the amount of RAM in GB"
    help
    exit 1
fi

if [ -z "$TYPE" ]; then
    echo "No database type specified. Specify the database type (web, oltp, dw, desktop, mixed)"
    help
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

# Set constants
MB=1024
GB=1048576

# Compute shared_buffers
case "$TYPE" in
    desktop) SHARED_BUFFERS=$(($RAM * $GB / 16))
    ;;
    *) SHARED_BUFFERS=$(($RAM * $GB / 4))
    ;;
esac

# Compute effective_cache_size
case "$TYPE" in
    desktop) EFFECTIVE_CACHE_SIZE=$(($RAM * $GB / 4))
    ;;
    *) EFFECTIVE_CACHE_SIZE=$(($RAM * $GB * 3 / 4))
    ;;
esac

# Compute maintenance_work_mem
case "$TYPE" in
    dw) MAINTENANCE_WORK_MEM=$(($RAM * $GB / 8))
    ;;
    *) MAINTENANCE_WORK_MEM=$(($RAM * $GB / 16))
    ;;
esac
MAINTENANCE_WORK_MEM_LIMIT=$((2 * $GB))
if [ "$MAINTENANCE_WORK_MEM" -gt $MAINTENANCE_WORK_MEM_LIMIT ]; then
    MAINTENANCE_WORK_MEM=$MAINTENANCE_WORK_MEM_LIMIT
fi

# Compute checkpoint_completion_target
CHECKPOINT_COMPLETION_TARGET=0.9

# Compute wal buffers
WAL_BUFFERS=$(($SHARED_BUFFERS * 3 / 100))
NEAR_WAL_BUFFER=$((14 * $MB))
MAX_WAL_BUFFER=$((16 * $MB))
if [ "$WAL_BUFFERS" -gt $NEAR_WAL_BUFFER ]; then
    WAL_BUFFERS=$MAX_WAL_BUFFER
fi

# Compute default_statistics_target
case "$TYPE" in
    dw) DEFAULT_STATISTICS_TARGET=500
    ;;
    *) DEFAULT_STATISTICS_TARGET=100
    ;;
esac

# Compute random_page_cost
case "$HARD_DRIVE" in
    hdd) RANDOM_PAGE_COST=4
    ;;
    *) RANDOM_PAGE_COST=1.1
    ;;
esac

# Compute effective_io_concurrency
case "$HARD_DRIVE" in
    hdd) EFFECTIVE_IO_CONCURRENCY=2
    ;;
    ssd) EFFECTIVE_IO_CONCURRENCY=200
    ;;
    san) EFFECTIVE_IO_CONCURRENCY=300
    ;;
esac

# Compute huge_pages
if [ "$RAM" -ge 32 ]; then
    HUGE_PAGES="try"
else
    HUGE_PAGES="off"
fi

# Compute min_wal_size
case "$TYPE" in
    oltp) MIN_WAL_SIZE=$((2048 * $MB))
    ;;
    dw) MIN_WAL_SIZE=$((4096 * $MB))
    ;;
    desktop) MIN_WAL_SIZE=$((100 * $MB))
    ;;
    *) MIN_WAL_SIZE=$((1024 * $MB))
    ;;
esac

# Compute max_wal_size
case "$TYPE" in
    oltp) MAX_WAL_SIZE=$((8192 * $MB))
    ;;
    dw) MAX_WAL_SIZE=$((16384 * $MB))
    ;;
    desktop) MAX_WAL_SIZE=$((2048 * $MB))
    ;;
    *) MAX_WAL_SIZE=$((4096 * $MB))
    ;;
esac

# Compute parallel 
if [ ! -z "$CPU" ] && [ "$CPU" -ge 4 ]; then
    MAX_WORKER_PROCESSES=$CPU
    MAX_PARALLEL_WORKERS=$CPU
    MAX_PARALLEL_WORKERS_PER_GATHER=$(($CPU / 2))
    MAX_PARALLEL_MAINTENANCE_WORKERS=$(($CPU / 2))
    if [ "$TYPE" != "dw" ] && [ "$MAX_PARALLEL_WORKERS_PER_GATHER" -gt 4 ]; then
        MAX_PARALLEL_WORKERS_PER_GATHER=4
    fi
    if [ "$MAX_PARALLEL_MAINTENANCE_WORKERS" -gt 4 ]; then
        MAX_PARALLEL_MAINTENANCE_WORKERS=4
    fi
fi

# Compute work_mem
PARALLEL_FOR_WORK_MEM=${MAX_PARALLEL_WORKERS_PER_GATHER:-2}
WORK_MEM_VALUE=$(( ($RAM * $GB - $SHARED_BUFFERS) / ($MAX_CONNECTIONS * 3) / $PARALLEL_FOR_WORK_MEM ))
case "$TYPE" in
    web) WORK_MEM=$WORK_MEM_VALUE
    ;;
    oltp) WORK_MEM=$WORK_MEM_VALUE
    ;;
    desktop) WORK_MEM=$(($WORK_MEM_VALUE / 6))
    ;;
    dw) WORK_MEM=$(($WORK_MEM_VALUE / 2))
    ;;
    mixed) WORK_MEM=$(($WORK_MEM_VALUE / 2))
    ;;
esac

function format {
    UNFORMATTED=$1
    if (( $UNFORMATTED % $GB == 0 )); then
        FORMATTED=$(( UNFORMATTED / GB ))"GB"
    elif (( $UNFORMATTED % $MB == 0 )); then
        FORMATTED=$(( UNFORMATTED / MB ))"MB"
    else
        FORMATTED=$UNFORMATTED"kB"
    fi
    echo $FORMATTED
}

if [ -z "$OUTPUT" ]; then
    cat <<- EOF
------------------------------------------------------------------------    
max_connections = '$MAX_CONNECTIONS'
shared_buffers = '$(format $SHARED_BUFFERS)'
effective_cache_size = '$(format $EFFECTIVE_CACHE_SIZE)'
maintenance_work_mem = '$(format $MAINTENANCE_WORK_MEM)'
checkpoint_completion_target = '$CHECKPOINT_COMPLETION_TARGET'
wal_buffers = '$(format $WAL_BUFFERS)'
default_statistics_target = '$DEFAULT_STATISTICS_TARGET'
random_page_cost = '$RANDOM_PAGE_COST'
effective_io_concurrency = '$EFFECTIVE_IO_CONCURRENCY'
work_mem = '$(format $WORK_MEM)'
huge_pages = '$HUGE_PAGES'
min_wal_size = '$(format $MIN_WAL_SIZE)'
max_wal_size = '$(format $MAX_WAL_SIZE)'
EOF

    if [ -n "$CPU" ]; then
        cat <<- EOF
max_worker_processes = '$MAX_WORKER_PROCESSES'
max_parallel_workers_per_gather = '$MAX_PARALLEL_WORKERS_PER_GATHER'
max_parallel_workers = '$MAX_PARALLEL_WORKERS'
max_parallel_maintenance_workers = '$MAX_PARALLEL_MAINTENANCE_WORKERS'
EOF
    fi
    echo "------------------------------------------------------------------------"
fi

if [[ $OUTPUT == "sql" ]]; then
    cat <<- EOF
------------------------------------------------------------------------
ALTER SYSTEM SET max_connections = '$MAX_CONNECTIONS';
ALTER SYSTEM SET shared_buffers = '$(format $SHARED_BUFFERS)';
ALTER SYSTEM SET effective_cache_size = '$(format $EFFECTIVE_CACHE_SIZE)';
ALTER SYSTEM SET maintenance_work_mem = '$(format $MAINTENANCE_WORK_MEM)';
ALTER SYSTEM SET checkpoint_completion_target = '$CHECKPOINT_COMPLETION_TARGET';
ALTER SYSTEM SET wal_buffers = '$(format $WAL_BUFFERS)';
ALTER SYSTEM SET default_statistics_target = '$DEFAULT_STATISTICS_TARGET';
ALTER SYSTEM SET random_page_cost = '$RANDOM_PAGE_COST';
ALTER SYSTEM SET effective_io_concurrency = '$EFFECTIVE_IO_CONCURRENCY';
ALTER SYSTEM SET work_mem = '$(format $WORK_MEM)';
ALTER SYSTEM SET huge_pages = '$HUGE_PAGES';
ALTER SYSTEM SET min_wal_size = '$(format $MIN_WAL_SIZE)';
ALTER SYSTEM SET max_wal_size = '$(format $MAX_WAL_SIZE)';
EOF

    if [ -n "$CPU" ]; then
        cat <<- EOF
ALTER SYSTEM SET max_worker_processes = '$MAX_WORKER_PROCESSES';
ALTER SYSTEM SET max_parallel_workers_per_gather = '$MAX_PARALLEL_WORKERS_PER_GATHER';
ALTER SYSTEM SET max_parallel_workers = '$MAX_PARALLEL_WORKERS';
ALTER SYSTEM SET max_parallel_maintenance_workers = '$MAX_PARALLEL_MAINTENANCE_WORKERS';
EOF
    fi
    echo "------------------------------------------------------------------------"
fi

