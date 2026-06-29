from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
import models
from routers import members, groups, payments, users, cashbook, prizes, join_requests

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Chit Fund Manager API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(members.router)
app.include_router(groups.router)
app.include_router(payments.router)
app.include_router(users.router)
app.include_router(cashbook.router)
app.include_router(prizes.router)
app.include_router(join_requests.router)


@app.get("/")
def read_root():
    return {"message": "Chit Fund Manager API is running!"}


@app.get("/health")
def health_check():
    return {"status": "ok"}