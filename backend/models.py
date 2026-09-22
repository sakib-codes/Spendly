from typing import Optional, List
from sqlmodel import Field, SQLModel
from datetime import datetime

class User(SQLModel, table=True):
    firebase_uid: str = Field(primary_key=True)
    email: str = Field(unique=True, index=True)
    full_name: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

class Category(SQLModel, table=True):
    id: str = Field(primary_key=True) # UUID from flutter
    firebase_uid: str = Field(index=True)
    name: str
    icon: str
    type: str # 'expense' or 'income'
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

class Transaction(SQLModel, table=True):
    id: str = Field(primary_key=True) # UUID from flutter
    firebase_uid: str = Field(index=True)
    category_id: str = Field(index=True)
    title: str
    amount: float
    type: str # 'expense' or 'income'
    date: datetime
    payment_method: str
    note: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None

class Budget(SQLModel, table=True):
    id: str = Field(primary_key=True) # UUID from flutter
    firebase_uid: str = Field(index=True)
    category_id: str = Field(index=True)
    amount: float
    month: datetime # First day of the month
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    deleted_at: Optional[datetime] = None
