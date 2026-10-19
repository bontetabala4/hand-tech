
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import settings
from app.routers import admin, auth, subscriptions, super_admin
from app.routers import predictions as legacy_predictions

app = FastAPI(title="Hand Tech API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routeurs de la nouvelle architecture
app.include_router(api_router, prefix="/api/v1")

# Routeurs historiques : authentification, historique,
# abonnements et administration.
app.include_router(auth.router, prefix="/api/v1")
app.include_router(legacy_predictions.router, prefix="/api/v1")
app.include_router(subscriptions.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(super_admin.router, prefix="/api/v1")



@app.get("/health", tags=["system"])
async def health():
    return {"status": "ok"}