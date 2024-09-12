from .models import Request
from .constants import *

def generate_config(request: Request) -> dict:
    validate_input(request)

    memory = request.memory * GB
    max_connections = request.max_connections if request.max_connections is not None else get_default_max_connections(request.database_type)
    
    shared_buffers = calculate_shared_buffers(memory, request.database_type)
    effective_cache_size = calculate_effective_cache_size(memory, request.database_type)
    maintenance_work_mem = calculate_maintenance_work_mem(memory, request.database_type)
    checkpoint_completion_target = "0.9"
    wal_buffers = calculate_wal_buffers(shared_buffers)
    default_statistics_target = calculate_default_statistics_target(request.database_type)
    random_page_cost = calculate_random_page_cost(request.storage_type)
    effective_io_concurrency = calculate_effective_io_concurrency(request.storage_type)
    work_mem = calculate_work_mem(memory, max_connections, shared_buffers, request.database_type, request.cpu)
    huge_pages = 'try' if request.memory >= 32 * GB else 'off'
    min_wal_size = calculate_min_wal_size(request.database_type)
    max_wal_size = calculate_max_wal_size(request.database_type)

    config = {
        'max_connections': str(max_connections),
        'shared_buffers': format_value(shared_buffers),
        'effective_cache_size': format_value(effective_cache_size),
        'maintenance_work_mem': format_value(maintenance_work_mem),
        'checkpoint_completion_target': checkpoint_completion_target,
        'wal_buffers': format_value(wal_buffers),
        'default_statistics_target': str(default_statistics_target),
        'random_page_cost': random_page_cost,
        'effective_io_concurrency': str(effective_io_concurrency),
        'work_mem': format_value(work_mem),
        'huge_pages': huge_pages,
        'min_wal_size': format_value(min_wal_size),
        'max_wal_size': format_value(max_wal_size)
    }

    if request.cpu and request.cpu >= 4:
        max_worker_processes = request.cpu
        max_parallel_workers = request.cpu
        max_parallel_workers_per_gather = min(request.cpu // 2, 4) if request.database_type != 'dw' else request.cpu // 2
        max_parallel_maintenance_workers = min(request.cpu // 2, 4)
        config.update({
            'max_worker_processes': str(max_worker_processes),
            'max_parallel_workers': str(max_parallel_workers),
            'max_parallel_workers_per_gather': str(max_parallel_workers_per_gather),
            'max_parallel_maintenance_workers': str(max_parallel_maintenance_workers)
        })

    return config

def validate_input(request: Request):
    if request.database_type not in DATABASE_TYPES:
        raise ValueError(f"Invalid database type. Choose from {DATABASE_TYPES}")
    if request.os_type not in OS_TYPES:
        raise ValueError(f"Invalid OS type. Choose from {OS_TYPES}")
    if request.storage_type not in STORAGE_TYPES:
        raise ValueError(f"Invalid storage type. Choose from {STORAGE_TYPES}")
    if request.postgres_version not in POSTGRES_VERSIONS:
        raise ValueError(f"Invalid PostgreSQL version. Choose from {POSTGRES_VERSIONS}")

def get_default_max_connections(database_type: str) -> int:
    return {
        'web': 200,
        'oltp': 300,
        'dw': 40,
        'desktop': 20,
        'mixed': 100
    }.get(database_type, 100)

def calculate_shared_buffers(memory: int, database_type: str) -> int:
    return memory // 16 if database_type == 'desktop' else memory // 4

def calculate_effective_cache_size(memory: int, database_type: str) -> int:
    return memory // 4 if database_type == 'desktop' else memory * 3 // 4

def calculate_maintenance_work_mem(memory: int, database_type: str) -> int:
    mem = memory // 8 if database_type == 'dw' else memory // 16
    return min(mem, 2 * GB)

def calculate_wal_buffers(shared_buffers: int) -> int:
    wal_buffers = shared_buffers * 3 // 100
    if wal_buffers > 14 * MB:
        return 16 * MB
    return wal_buffers

def calculate_default_statistics_target(database_type: str) -> int:
    return 500 if database_type == 'dw' else 100

def calculate_random_page_cost(storage_type: str) -> float:
    return '4.0' if storage_type == 'hdd' else '1.1'

def calculate_effective_io_concurrency(storage_type: str) -> int:
    return {
        'hdd': 2,
        'ssd': 200,
        'san': 300
    }.get(storage_type, 200)

def calculate_work_mem(memory: int, max_connections: int, shared_buffers: int, database_type: str, cpu: int) -> int:
    parallel_for_work_mem = min(cpu // 2, 4) if cpu and cpu >= 4 else 2
    work_mem_value = (memory - shared_buffers) // (max_connections * 3) // parallel_for_work_mem
    return {
        'web': work_mem_value,
        'oltp': work_mem_value,
        'desktop': work_mem_value // 6,
        'dw': work_mem_value // 2,
        'mixed': work_mem_value // 2
    }.get(database_type, work_mem_value)

def calculate_min_wal_size(database_type: str) -> int:
    return {
        'oltp': 2048 * MB,
        'dw': 4096 * MB,
        'desktop': 100 * MB
    }.get(database_type, 1024 * MB)

def calculate_max_wal_size(database_type: str) -> int:
    return {
        'oltp': 8192 * MB,
        'dw': 16384 * MB,
        'desktop': 2048 * MB
    }.get(database_type, 4096 * MB)

def format_value(value: int) -> str:
    if value % GB == 0:
        return f"{value // GB}GB"
    elif value % MB == 0:
        return f"{value // MB}MB"
    else:
        return f"{value}kB"