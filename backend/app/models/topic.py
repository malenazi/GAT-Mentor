from sqlalchemy import Column, Float, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class Topic(Base):
    __tablename__ = "topics"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    slug = Column(String, unique=True, nullable=False)
    description = Column(String, nullable=True)
    weight_in_exam = Column(Float, default=0.33)
    display_order = Column(Integer, default=0)

    concepts = relationship("Concept", back_populates="topic")
