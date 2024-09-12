from fastapi import APIRouter, HTTPException
from ..models import Request, Response
from ..generator import generate_config
from ..constants import DEFAULT_POSTGRES_VERSION, DEFAULT_OS_TYPE, DEFAULT_STORAGE_TYPE

router = APIRouter()

@router.get("/", response_model=Response)
async def tune_postgres(
    memory: int,
    database_type: str,
    max_connections: int = None,
    postgres_version: int = DEFAULT_POSTGRES_VERSION,
    os_type: str = DEFAULT_OS_TYPE,
    storage_type: str = DEFAULT_STORAGE_TYPE,
    cpu: int = None
):
    try:
        request = Request(
            memory=memory,
            database_type=database_type,
            max_connections=max_connections,
            postgres_version=postgres_version,
            os_type=os_type,
            storage_type=storage_type,
            cpu=cpu 
        )
        config = generate_config(request)
        return Response(config=config)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))