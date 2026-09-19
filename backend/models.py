from typing import Optional
from sqlmodel import Field, SQLModel

# This represents exactly what the 'user' table will look like in the Neon Database
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True)
    full_name: str
