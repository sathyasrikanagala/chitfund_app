from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid

from database import get_db
import models
import schemas

router = APIRouter(prefix="/join-requests", tags=["join-requests"])


@router.post("/", response_model=schemas.JoinRequestResponse)
def create_join_request(payload: schemas.JoinRequestCreate, db: Session = Depends(get_db)):
    existing = db.query(models.JoinRequest).filter(
        models.JoinRequest.user_id == payload.user_id,
        models.JoinRequest.group_id == payload.group_id,
        models.JoinRequest.status == "pending",
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="You already have a pending request for this group")

    req = models.JoinRequest(**payload.model_dump())
    db.add(req)
    db.commit()
    db.refresh(req)
    return req


@router.get("/", response_model=List[schemas.JoinRequestResponse])
def get_join_requests(status: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(models.JoinRequest)
    if status:
        query = query.filter(models.JoinRequest.status == status)
    return query.order_by(models.JoinRequest.created_at.desc()).all()


@router.put("/{request_id}/approval", response_model=schemas.JoinRequestResponse)
def update_join_request(
    request_id: str,
    payload: schemas.JoinRequestApproval,
    db: Session = Depends(get_db),
):
    if payload.status not in ("approved", "rejected"):
        raise HTTPException(status_code=400, detail="status must be 'approved' or 'rejected'")

    req = db.query(models.JoinRequest).filter(models.JoinRequest.id == request_id).first()
    if not req:
        raise HTTPException(status_code=404, detail="Join request not found")

    if payload.status == "approved":
        # Create the actual Member record, link it to the requesting user
        member = models.Member(
            id=str(uuid.uuid4()),
            name=req.full_name,
            mobile=req.mobile or "",
            village="",  # agent can fill in details later via member edit screen
            status="Active",
        )
        db.add(member)

        user = db.query(models.User).filter(models.User.id == req.user_id).first()
        if user:
            user.member_id = member.id

        req.member_id = member.id

    req.status = payload.status
    db.commit()
    db.refresh(req)
    return req
@router.get("/group/{group_id}/members")
def get_group_members(group_id: str, db: Session = Depends(get_db)):
    """Returns all approved members for a given group, with their member_id."""
    approved = db.query(models.JoinRequest).filter(
        models.JoinRequest.group_id == group_id,
        models.JoinRequest.status == "approved",
    ).all()

    member_ids = [r.member_id for r in approved if r.member_id]
    members = db.query(models.Member).filter(models.Member.id.in_(member_ids)).all()
    return members

@router.post("/direct-add", response_model=schemas.JoinRequestResponse)
def direct_add_member(payload: schemas.DirectAddRequest, db: Session = Depends(get_db)):
    """Agent adds an existing Member directly to a group — no approval needed."""
    member = db.query(models.Member).filter(models.Member.id == payload.member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")

    existing = db.query(models.JoinRequest).filter(
        models.JoinRequest.member_id == payload.member_id,
        models.JoinRequest.group_id == payload.group_id,
        models.JoinRequest.status == "approved",
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Member is already in this group")

    req = models.JoinRequest(
        user_id="agent-direct-add",  # no real user account involved
        member_id=member.id,
        group_id=payload.group_id,
        full_name=member.name,
        mobile=member.mobile,
        status="approved",
    )
    db.add(req)
    db.commit()
    db.refresh(req)
    return req