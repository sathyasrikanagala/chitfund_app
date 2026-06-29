from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from database import get_db
import models
import schemas

router = APIRouter(prefix="/groups", tags=["groups"])


@router.post("/", response_model=schemas.GroupResponse)
def create_group(group: schemas.GroupCreate, db: Session = Depends(get_db)):
    db_group = models.ChitGroup(**group.model_dump())
    db.add(db_group)
    db.commit()
    db.refresh(db_group)
    return db_group


@router.get("/", response_model=List[schemas.GroupResponse])
def get_groups(db: Session = Depends(get_db)):
    return db.query(models.ChitGroup).order_by(
        models.ChitGroup.created_at.desc()).all()


@router.get("/{group_id}", response_model=schemas.GroupResponse)
def get_group(group_id: str, db: Session = Depends(get_db)):
    group = db.query(models.ChitGroup).filter(
        models.ChitGroup.id == group_id).first()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
    return group


@router.put("/{group_id}", response_model=schemas.GroupResponse)
def update_group(group_id: str, group: schemas.GroupCreate, db: Session = Depends(get_db)):
    db_group = db.query(models.ChitGroup).filter(
        models.ChitGroup.id == group_id).first()
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")
    for key, value in group.model_dump().items():
        setattr(db_group, key, value)
    db.commit()
    db.refresh(db_group)
    return db_group


@router.delete("/{group_id}")
def delete_group(group_id: str, db: Session = Depends(get_db)):
    db_group = db.query(models.ChitGroup).filter(
        models.ChitGroup.id == group_id).first()
    if not db_group:
        raise HTTPException(status_code=404, detail="Group not found")
    db.delete(db_group)
    db.commit()
    return {"message": "Group deleted"}