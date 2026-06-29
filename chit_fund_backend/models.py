import uuid
from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, DateTime
from database import Base


def generate_uuid():
    return str(uuid.uuid4())


class Member(Base):
    __tablename__ = "members"

    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String, nullable=False)
    mobile = Column(String, nullable=False)
    father_name = Column(String, nullable=True)
    village = Column(String, nullable=False)
    address = Column(String, nullable=True)
    id_proof_type = Column(String, nullable=True)
    id_proof_number = Column(String, nullable=True)
    nominee_name = Column(String, nullable=True)
    nominee_mobile = Column(String, nullable=True)
    status = Column(String, default="Active")
    created_at = Column(DateTime, default=datetime.utcnow)


class ChitGroup(Base):
    __tablename__ = "chit_groups"

    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    total_members = Column(Integer, nullable=False)
    frequency = Column(String, nullable=False)
    draw_method = Column(String, default="Auction")
    commission_percent = Column(Float, default=0)
    start_date = Column(String, nullable=False)
    status = Column(String, default="Active")
    created_at = Column(DateTime, default=datetime.utcnow)


class Payment(Base):
    __tablename__ = "payments"

    id = Column(String, primary_key=True, default=generate_uuid)
    member_id = Column(String, nullable=False)
    group_id = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    payment_type = Column(String, nullable=False)
    payment_mode = Column(String, nullable=False)
    installment_number = Column(Integer, nullable=True)
    notes = Column(String, nullable=True)
    paid_at = Column(DateTime, default=datetime.utcnow)


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=generate_uuid)
    username = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    mobile = Column(String, nullable=True)
    role = Column(String, nullable=False)          # agent / member
    status = Column(String, default="approved")     # agent auto-approved; member pending until added to a group
    member_id = Column(String, nullable=True)        # links a member-role user to their Member record
    created_at = Column(DateTime, default=datetime.utcnow)


class CashEntry(Base):
    __tablename__ = "cashbook"

    id = Column(String, primary_key=True, default=generate_uuid)
    type = Column(String, nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    amount = Column(Float, nullable=False)
    payment_mode = Column(String, nullable=True)
    reference_id = Column(String, nullable=True)
    entry_date = Column(DateTime, default=datetime.utcnow)


class PrizeEntry(Base):
    __tablename__ = "prize_entries"

    id = Column(String, primary_key=True, default=generate_uuid)
    group_id = Column(String, nullable=False)
    member_id = Column(String, nullable=False)
    installment_number = Column(Integer, nullable=True)
    chit_value = Column(Float, nullable=False)
    discount_amount = Column(Float, default=0)
    commission_amount = Column(Float, default=0)
    net_payout = Column(Float, nullable=False)
    draw_method = Column(String, nullable=True)
    witnesses = Column(String, nullable=True)
    notes = Column(String, nullable=True)
    prize_date = Column(DateTime, default=datetime.utcnow)

class JoinRequest(Base):
    __tablename__ = "join_requests"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, nullable=False)       # the member's user account id
    member_id = Column(String, nullable=True)      # set once approved & a Member record exists
    group_id = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    mobile = Column(String, nullable=True)
    status = Column(String, default="pending")     # pending / approved / rejected
    created_at = Column(DateTime, default=datetime.utcnow)