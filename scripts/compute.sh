#!/bin/bash

source ./scripts/validate.sh

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

