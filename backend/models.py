from typing import Optional, Any
from sqlmodel import Field, SQLModel
from pydantic import AliasChoices, field_validator, ValidationInfo
from datetime import datetime, timezone

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

def parse_epoch_dt(v: Any) -> Any:
    if v is None:
        return None
    if isinstance(v, datetime):
        return v
    if isinstance(v, (int, float)):
        if v == 0:
            return utc_now()
        # Milliseconds to seconds if needed
        if v > 10000000000:
            v = v / 1000.0
        return datetime.fromtimestamp(v, tz=timezone.utc)
    if isinstance(v, str):
        # Parse ISO-8601 string into timezone-aware datetime
        dt = datetime.fromisoformat(v.replace('Z', '+00:00'))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    return v

class User(SQLModel, table=True):
    firebase_uid: str = Field(primary_key=True)
    email: str = Field(unique=True, index=True)
    full_name: Optional[str] = None
    created_at: datetime = Field(default_factory=utc_now)

class Category(SQLModel, table=True):
    id: str = Field(primary_key=True) # UUID from flutter
    firebase_uid: Optional[str] = Field(default=None, index=True)
    name: str
    icon: str
    type: str # 'expense', 'income', or 'both'
    created_at: datetime = Field(
        default_factory=utc_now,
        validation_alias=AliasChoices('created_at', 'createdAt')
    )
    updated_at: datetime = Field(
        default_factory=utc_now,
        validation_alias=AliasChoices('updated_at', 'updatedAt')
    )
    deleted_at: Optional[datetime] = Field(
        default=None,
        validation_alias=AliasChoices('deleted_at', 'deletedAt')
    )

    @field_validator('created_at', 'updated_at', 'deleted_at', mode='before')
    @classmethod
    def validate_timestamps(cls, v: Any) -> Any:
        return parse_epoch_dt(v)

class Transaction(SQLModel, table=True):
    id: str = Field(primary_key=True) # UUID from flutter
    firebase_uid: Optional[str] = Field(default=None, index=True)
    category_id: str = Field(
        index=True,
        validation_alias=AliasChoices('category_id', 'categoryId')
    )
    title: str
    amount: float
    type: str # 'expense' or 'income'
    date: datetime
    payment_method: str = Field(
        default='Cash',
        validation_alias=AliasChoices('payment_method', 'paymentMethod')
    )
    note: Optional[str] = None
    created_at: datetime = Field(
        default_factory=utc_now,
        validation_alias=AliasChoices('created_at', 'createdAt')
    )
    updated_at: datetime = Field(
        default_factory=utc_now,
        validation_alias=AliasChoices('updated_at', 'updatedAt')
    )
    deleted_at: Optional[datetime] = Field(
        default=None,
        validation_alias=AliasChoices('deleted_at', 'deletedAt')
    )

    @field_validator('date', 'created_at', 'updated_at', 'deleted_at', mode='before')
    @classmethod
    def validate_transaction_dates(cls, v: Any) -> Any:
        return parse_epoch_dt(v)

class Budget(SQLModel, table=True):
    id: str = Field(primary_key=True) # UUID from flutter
    firebase_uid: Optional[str] = Field(default=None, index=True)
    category_id: str = Field(
        index=True,
        validation_alias=AliasChoices('category_id', 'categoryId')
    )
    amount: float
    month: datetime # First day of the month in UTC
    created_at: datetime = Field(
        default_factory=utc_now,
        validation_alias=AliasChoices('created_at', 'createdAt')
    )
    updated_at: datetime = Field(
        default_factory=utc_now,
        validation_alias=AliasChoices('updated_at', 'updatedAt')
    )
    deleted_at: Optional[datetime] = Field(
        default=None,
        validation_alias=AliasChoices('deleted_at', 'deletedAt')
    )

    @field_validator('month', mode='before')
    @classmethod
    def validate_budget_month(cls, v: Any, info: ValidationInfo) -> Any:
        if isinstance(v, (int, float)):
            if 1 <= v <= 12:
                year = 2026
                if info.data and 'year' in info.data:
                    year = int(info.data['year'])
                return datetime(year, int(v), 1, tzinfo=timezone.utc)
            return parse_epoch_dt(v)
        return parse_epoch_dt(v)

    @field_validator('created_at', 'updated_at', 'deleted_at', mode='before')
    @classmethod
    def validate_budget_timestamps(cls, v: Any) -> Any:
        return parse_epoch_dt(v)
