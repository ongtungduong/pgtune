from pydantic import BaseModel, Field
from typing import Dict, Union, Optional

class Request(BaseModel):
    memory: int = Field(..., description="System memory in GB")
    database_type: str = Field(..., description="Database type (web, oltp, dw, desktop, mixed)")
    max_connections: Optional[int] = Field(None, description="Maximum number of PostgreSQL connections")
    postgres_version: Optional[int] = Field(None, description="PostgreSQL version")
    os_type: Optional[str] = Field(None, description="Operating system type")
    storage_type: Optional[str] = Field(None, description="Storage type")
    cpu: Optional[int] = Field(None, description="Number of CPUs")

class Response(BaseModel):
    config: Dict[str, Union[str, int]]