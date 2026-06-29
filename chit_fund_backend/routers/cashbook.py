from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from database import get_db
import models
import schemas

router = APIRouter(prefix="/cashbook", tags=["cashbook"])


@router.post("/", response_model=schemas.CashEntryResponse)
def create_entry(entry: schemas.CashEntryCreate, db: Session = Depends(get_db)):
    db_entry = models.CashEntry(**entry.model_dump())
    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)
    return db_entry


@router.get("/", response_model=List[schemas.CashEntryResponse])
def get_entries(db: Session = Depends(get_db)):
    return db.query(models.CashEntry).order_by(
        models.CashEntry.entry_date.desc()).all()