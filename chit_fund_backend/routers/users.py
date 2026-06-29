from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
import models
import schemas

router = APIRouter(prefix="/users", tags=["users"])


# ── Registration ──────────────────────────────────────────────────────────────

@router.post("/register", response_model=schemas.UserResponse)
def register(payload: schemas.RegisterRequest, db: Session = Depends(get_db)):
    role = payload.role.lower()

    if role not in ("agent", "member"):
        raise HTTPException(status_code=400, detail="Invalid role")

    if db.query(models.User).filter(models.User.username == payload.username).first():
        raise HTTPException(status_code=400, detail="Username already taken")

    # Agents are immediately active. Members are active too —
    # but they won't see any group data until a join request is approved.
    user = models.User(
        username=payload.username,
        password=payload.password,
        full_name=payload.full_name,
        mobile=payload.mobile,
        role=role,
        status="approved",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


# ── Login ─────────────────────────────────────────────────────────────────────

@router.post("/login", response_model=schemas.LoginResponse)
def login(credentials: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(
        models.User.username == credentials.username).first()

    if not user or user.password != credentials.password:
        raise HTTPException(status_code=401, detail="Invalid username or password")

    return schemas.LoginResponse(
        id=user.id,
        username=user.username,
        full_name=user.full_name,
        mobile=user.mobile,
        role=user.role,
        status=user.status,
        member_id=user.member_id,
    )


# ── General CRUD ──────────────────────────────────────────────────────────────

@router.get("/", response_model=List[schemas.UserResponse])
def get_users(db: Session = Depends(get_db)):
    return db.query(models.User).all()


@router.put("/{user_id}/password")
def update_password(user_id: str, new_password: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.password = new_password
    db.commit()
    return {"message": "Password updated"}

@router.put("/{user_id}/profile", response_model=schemas.UserResponse)
def update_profile(user_id: str, payload: schemas.ProfileUpdate, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.full_name = payload.full_name
    user.mobile = payload.mobile
    db.commit()
    db.refresh(user)

    # If this user is linked to a Member record, keep that name/mobile in sync too
    if user.member_id:
        member = db.query(models.Member).filter(models.Member.id == user.member_id).first()
        if member:
            member.name = payload.full_name
            member.mobile = payload.mobile
            db.commit()

    return user