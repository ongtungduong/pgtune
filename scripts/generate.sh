#!/bin/bash

source ./scripts/compute.sh

if [[ $1 == "conf" ]]; then
    cat <<- EOF

max_connections = '$MAX_CONNECTIONS'
shared_buffers = '$(bash ./scripts/format.sh $SHARED_BUFFERS)'
effective_cache_size = '$(bash ./scripts/format.sh $EFFECTIVE_CACHE_SIZE)'
maintenance_work_mem = '$(bash ./scripts/format.sh $MAINTENANCE_WORK_MEM)'
checkpoint_completion_target = '$CHECKPOINT_COMPLETION_TARGET'
wal_buffers = '$(bash ./scripts/format.sh $WAL_BUFFERS)'
default_statistics_target = '$DEFAULT_STATISTICS_TARGET'
random_page_cost = '$RANDOM_PAGE_COST'
effective_io_concurrency = '$EFFECTIVE_IO_CONCURRENCY'
work_mem = '$(bash ./scripts/format.sh $WORK_MEM)'
huge_pages = '$HUGE_PAGES'
min_wal_size = '$(bash ./scripts/format.sh $MIN_WAL_SIZE)'
max_wal_size = '$(bash ./scripts/format.sh $MAX_WAL_SIZE)'
EOF

    if [ -n "$CPU" ]; then
        cat <<- EOF
max_worker_processes = '$MAX_WORKER_PROCESSES'
max_parallel_workers_per_gather = '$MAX_PARALLEL_WORKERS_PER_GATHER'
max_parallel_workers = '$MAX_PARALLEL_WORKERS'
max_parallel_maintenance_workers = '$MAX_PARALLEL_MAINTENANCE_WORKERS'
EOF
    fi
fi

if [[ $1 == "sql" ]]; then
    cat <<- EOF
    
ALTER SYSTEM SET max_connections = '$MAX_CONNECTIONS';
ALTER SYSTEM SET shared_buffers = '$(bash ./scripts/format.sh $SHARED_BUFFERS)';
ALTER SYSTEM SET effective_cache_size = '$(bash ./scripts/format.sh $EFFECTIVE_CACHE_SIZE)';
ALTER SYSTEM SET maintenance_work_mem = '$(bash ./scripts/format.sh $MAINTENANCE_WORK_MEM)';
ALTER SYSTEM SET checkpoint_completion_target = '$CHECKPOINT_COMPLETION_TARGET';
ALTER SYSTEM SET wal_buffers = '$(bash ./scripts/format.sh $WAL_BUFFERS)';
ALTER SYSTEM SET default_statistics_target = '$DEFAULT_STATISTICS_TARGET';
ALTER SYSTEM SET random_page_cost = '$RANDOM_PAGE_COST';
ALTER SYSTEM SET effective_io_concurrency = '$EFFECTIVE_IO_CONCURRENCY';
ALTER SYSTEM SET work_mem = '$(bash ./scripts/format.sh $WORK_MEM)';
ALTER SYSTEM SET huge_pages = '$HUGE_PAGES';
ALTER SYSTEM SET min_wal_size = '$(bash ./scripts/format.sh $MIN_WAL_SIZE)';
ALTER SYSTEM SET max_wal_size = '$(bash ./scripts/format.sh $MAX_WAL_SIZE)';
EOF

    if [ -n "$CPU" ]; then
        cat <<- EOF
ALTER SYSTEM SET max_worker_processes = '$MAX_WORKER_PROCESSES';
ALTER SYSTEM SET max_parallel_workers_per_gather = '$MAX_PARALLEL_WORKERS_PER_GATHER';
ALTER SYSTEM SET max_parallel_workers = '$MAX_PARALLEL_WORKERS';
ALTER SYSTEM SET max_parallel_maintenance_workers = '$MAX_PARALLEL_MAINTENANCE_WORKERS';
EOF
    fi
fi
