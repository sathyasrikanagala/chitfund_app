from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
import models
import schemas

router = APIRouter(prefix="/prizes", tags=["prizes"])


@router.post("/", response_model=schemas.PrizeEntryResponse)
def create_prize(prize: schemas.PrizeEntryCreate, db: Session = Depends(get_db)):
    db_prize = models.PrizeEntry(**prize.model_dump())
    db.add(db_prize)
    db.commit()
    db.refresh(db_prize)
    return db_prize


@router.get("/", response_model=List[schemas.PrizeEntryResponse])
def get_prizes(group_id: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(models.PrizeEntry)
    if group_id:
        query = query.filter(models.PrizeEntry.group_id == group_id)
    return query.order_by(models.PrizeEntry.prize_date.desc()).all()