from typing import Any, Generic, List, Optional
from app.repositories.base import BaseRepository, ModelType

class BaseService(Generic[ModelType]):
    """Base class for all business services, coordinating calls to the repository layer."""
    
    def __init__(self, repository: BaseRepository[ModelType]):
        self.repository = repository

    async def get_by_id(self, id: Any) -> Optional[ModelType]:
        """Fetch a single record by ID."""
        return await self.repository.get(id)

    async def get_list(self, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """Fetch a list of records with offset and limit pagination."""
        return await self.repository.list(skip=skip, limit=limit)

    async def create(self, obj_in: dict[str, Any]) -> ModelType:
        """Create a new record."""
        return await self.repository.create(obj_in)

    async def update(self, id: Any, obj_in: dict[str, Any]) -> Optional[ModelType]:
        """Update fields on an existing record."""
        db_obj = await self.repository.get(id)
        if not db_obj:
            return None
        return await self.repository.update(db_obj, obj_in)

    async def delete(self, id: Any) -> bool:
        """Delete a record by ID."""
        return await self.repository.delete(id)
