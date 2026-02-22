from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class Concept(Base):
    __tablename__ = "concepts"

    id = Column(Integer, primary_key=True, index=True)
    topic_id = Column(Integer, ForeignKey("topics.id"), nullable=False)
    name = Column(String, nullable=False)
    slug = Column(String, unique=True, nullable=False)
    description = Column(String, nullable=True)
    prerequisite_concept_id = Column(Integer, ForeignKey("concepts.id"), nullable=True)
    display_order = Column(Integer, default=0)

    topic = relationship("Topic", back_populates="concepts")
    questions = relationship("Question", back_populates="concept")
    user_stats = relationship("UserConceptStats", back_populates="concept")
