from fastapi import APIRouter

router = APIRouter()

@router.get("/health")
async def health():
    return {
        "status_code": 200,
        "message": "OK"
    }