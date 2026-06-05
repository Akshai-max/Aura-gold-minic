from typing import Any, Generic, List, Optional, Type, TypeVar
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.base import Base

ModelType = TypeVar("ModelType", bound=Base)

class BaseRepository(Generic[ModelType]):
    """Generic async repository implementing core CRUD operations for SQLAlchemy models."""
    
    def __init__(self, model: Type[ModelType], db_session: AsyncSession):
        self.model = model
        self.db = db_session

    async def get(self, id: Any) -> Optional[ModelType]:
        """Fetch a single record by its primary key ID."""
        return await self.db.get(self.model, id)

    async def list(self, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """Fetch a list of records with offset and limit pagination."""
        query = select(self.model).offset(skip).limit(limit)
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def create(self, obj_in: dict[str, Any], commit: bool = True) -> ModelType:
        """Create and optionally save a new record."""
        db_obj = self.model(**obj_in)
        self.db.add(db_obj)
        if commit:
            await self.db.commit()
            await self.db.refresh(db_obj)
        return db_obj

    async def update(self, db_obj: ModelType, obj_in: dict[str, Any], commit: bool = True) -> ModelType:
        """Update fields on an existing record."""
        for field, value in obj_in.items():
            if hasattr(db_obj, field):
                setattr(db_obj, field, value)
        self.db.add(db_obj)
        if commit:
            await self.db.commit()
            await self.db.refresh(db_obj)
        return db_obj

    async def delete(self, id: Any, commit: bool = True) -> bool:
        """Delete a record by primary key ID."""
        db_obj = await self.get(id)
        if not db_obj:
            return False
        await self.db.delete(db_obj)
        if commit:
            await self.db.commit()
        return True
