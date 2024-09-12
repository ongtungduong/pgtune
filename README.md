# PGTune

PGTune is a FastAPI-based web service that generates optimized PostgreSQL configuration based on your system's specifications and workload.

## Dependencies

```
pip install -r requirements.txt
```

## Usage

1. Start the server:
   ```
   uvicorn main:app --reload
   ```

2. API docs is available at `http://localhost:8000/docs`

3. Use the following query parameters:
   - `memory`: Total system memory in GB (required)
   - `database_type`: Type of database workload (required) (web, oltp, dw, desktop, mixed)
   - `max_connections`: Maximum number of concurrent connections (optional)
   - `postgres_version`: PostgreSQL version (default: 16)
   - `os_type`: Operating system type (default: linux) (linux, windows, macos)
   - `storage_type`: Storage type (default: ssd) (ssd, hdd)
   - `cpu`: Number of CPU cores (optional)

4. You can also use the bash script `pgtune.sh` to tune your PostgreSQL configuration.

Example:

```
./pgtune.sh -c 4 -r 16 -t mixed -k 600 -d ssd -o sql
```
