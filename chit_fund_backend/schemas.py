from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class MemberCreate(BaseModel):
    name: str
    mobile: str
    father_name: Optional[str] = None
    village: str
    address: Optional[str] = None
    id_proof_type: Optional[str] = None
    id_proof_number: Optional[str] = None
    nominee_name: Optional[str] = None
    nominee_mobile: Optional[str] = None
    status: str = "Active"


class MemberResponse(MemberCreate):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True


class GroupCreate(BaseModel):
    name: str
    amount: float
    total_members: int
    frequency: str
    draw_method: str = "Auction"
    commission_percent: float = 0
    start_date: str
    status: str = "Active"


class GroupResponse(GroupCreate):
    id: str
    created_at: datetime

    class Config:
        from_attributes = True


class PaymentCreate(BaseModel):
    member_id: str
    group_id: str
    amount: float
    payment_type: str
    payment_mode: str
    installment_number: Optional[int] = None
    notes: Optional[str] = None


class PaymentResponse(PaymentCreate):
    id: str
    paid_at: datetime

    class Config:
        from_attributes = True


# ── Auth ─────────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    username: str
    password: str
    full_name: str
    mobile: Optional[str] = None
    role: str  # "agent" | "member"


class UserResponse(BaseModel):
    id: str
    username: str
    full_name: str
    mobile: Optional[str] = None
    role: str
    status: str
    member_id: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    id: str
    username: str
    full_name: str
    mobile: Optional[str] = None
    role: str
    status: str
    member_id: Optional[str] = None


# ── Join Requests ──────────────────────────────────────────────────────────────

class JoinRequestCreate(BaseModel):
    user_id: str
    group_id: str
    full_name: str
    mobile: Optional[str] = None


class JoinRequestResponse(JoinRequestCreate):
    id: str
    member_id: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class JoinRequestApproval(BaseModel):
    status: str  # "approved" | "rejected"

class DirectAddRequest(BaseModel):
    member_id: str
    group_id: str


# ── Cash & Prizes ─────────────────────────────────────────────────────────────

class CashEntryCreate(BaseModel):
    type: str
    name: str
    description: Optional[str] = None
    amount: float
    payment_mode: Optional[str] = None
    reference_id: Optional[str] = None


class CashEntryResponse(CashEntryCreate):
    id: str
    entry_date: datetime

    class Config:
        from_attributes = True


class PrizeEntryCreate(BaseModel):
    group_id: str
    member_id: str
    installment_number: Optional[int] = None
    chit_value: float
    discount_amount: float = 0
    commission_amount: float = 0
    net_payout: float
    draw_method: Optional[str] = None
    witnesses: Optional[str] = None
    notes: Optional[str] = None


class PrizeEntryResponse(PrizeEntryCreate):
    id: str
    prize_date: datetime

    class Config:
        from_attributes = True

class ProfileUpdate(BaseModel):
    full_name: str
    mobile: Optional[str] = None