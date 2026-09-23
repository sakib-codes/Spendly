from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime, timezone
import logging

from database import get_session
from models import Transaction, Category, Budget, User
from auth import verify_token

logger = logging.getLogger("spendly.sync")

router = APIRouter(prefix="/sync", tags=["Sync"])

class SyncPushRequest(BaseModel):
    transactions: List[Transaction] = []
    categories: List[Category] = []
    budgets: List[Budget] = []

class SyncPullResponse(BaseModel):
    transactions: List[Transaction]
    categories: List[Category]
    budgets: List[Budget]
    server_timestamp: datetime

@router.post("/push")
def push_sync(
    payload: SyncPushRequest, 
    session: Session = Depends(get_session),
    token_data: dict = Depends(verify_token)
):
    uid = token_data.get("uid")
    if not uid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    try:
        # Process Categories
        for cat in payload.categories:
            if cat.firebase_uid != uid:
                cat.firebase_uid = uid
            existing = session.get(Category, cat.id)
            if existing:
                update_data = cat.model_dump(exclude_unset=True)
                for key, value in update_data.items():
                    setattr(existing, key, value)
                session.add(existing)
            else:
                session.add(cat)
                
        # Process Transactions
        for txn in payload.transactions:
            if txn.firebase_uid != uid:
                txn.firebase_uid = uid
            existing = session.get(Transaction, txn.id)
            if existing:
                update_data = txn.model_dump(exclude_unset=True)
                for key, value in update_data.items():
                    setattr(existing, key, value)
                session.add(existing)
            else:
                session.add(txn)
                
        # Process Budgets
        for bud in payload.budgets:
            if bud.firebase_uid != uid:
                bud.firebase_uid = uid
            existing = session.get(Budget, bud.id)
            if existing:
                update_data = bud.model_dump(exclude_unset=True)
                for key, value in update_data.items():
                    setattr(existing, key, value)
                session.add(existing)
            else:
                session.add(bud)
                
        session.commit()
        return {"status": "success"}
    except Exception as e:
        session.rollback()
        logger.error(f"Sync push failed: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database sync failed: {e}")

@router.get("/pull", response_model=SyncPullResponse)
def pull_sync(
    last_sync_timestamp: Optional[datetime] = None,
    session: Session = Depends(get_session),
    token_data: dict = Depends(verify_token)
):
    uid = token_data.get("uid")
    if not uid:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    
    # Ensure last_sync_timestamp is timezone-aware UTC if passed as naive
    if last_sync_timestamp and last_sync_timestamp.tzinfo is None:
        last_sync_timestamp = last_sync_timestamp.replace(tzinfo=timezone.utc)
    
    try:
        if last_sync_timestamp:
            cats = session.exec(select(Category).where(Category.firebase_uid == uid).where(Category.updated_at >= last_sync_timestamp)).all()
            txns = session.exec(select(Transaction).where(Transaction.firebase_uid == uid).where(Transaction.updated_at >= last_sync_timestamp)).all()
            buds = session.exec(select(Budget).where(Budget.firebase_uid == uid).where(Budget.updated_at >= last_sync_timestamp)).all()
        else:
            cats = session.exec(select(Category).where(Category.firebase_uid == uid)).all()
            txns = session.exec(select(Transaction).where(Transaction.firebase_uid == uid)).all()
            buds = session.exec(select(Budget).where(Budget.firebase_uid == uid)).all()
            
        return SyncPullResponse(
            categories=cats,
            transactions=txns,
            budgets=buds,
            server_timestamp=datetime.now(timezone.utc)
        )
    except Exception as e:
        logger.error(f"Sync pull failed: {e}", exc_info=True)
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Database sync failed: {e}")
