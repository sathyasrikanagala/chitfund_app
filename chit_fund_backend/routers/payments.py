from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional

from database import get_db
import models
import schemas

router = APIRouter(prefix="/payments", tags=["payments"])


@router.post("/", response_model=schemas.PaymentResponse)
def create_payment(payment: schemas.PaymentCreate, db: Session = Depends(get_db)):
    db_payment = models.Payment(**payment.model_dump())
    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    return db_payment


@router.get("/", response_model=List[schemas.PaymentResponse])
def get_payments(
    member_id: Optional[str] = None,
    group_id: Optional[str] = None,
    db: Session = Depends(get_db),
):
    query = db.query(models.Payment)
    if member_id:
        query = query.filter(models.Payment.member_id == member_id)
    if group_id:
        query = query.filter(models.Payment.group_id == group_id)
    return query.order_by(models.Payment.paid_at.desc()).all()


@router.get("/{payment_id}", response_model=schemas.PaymentResponse)
def get_payment(payment_id: str, db: Session = Depends(get_db)):
    payment = db.query(models.Payment).filter(
        models.Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    return payment