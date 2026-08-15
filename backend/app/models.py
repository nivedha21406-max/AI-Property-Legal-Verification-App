from sqlalchemy import (
    Column, Integer, String, Float, Text, DateTime, ForeignKey, Boolean
)
from sqlalchemy.orm import relationship
from datetime import datetime
from .database import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String(150), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(30), default="buyer")  # buyer, seller, bank, lawyer, admin
    created_at = Column(DateTime, default=datetime.utcnow)


class Property(Base):
    __tablename__ = "properties"
    id = Column(Integer, primary_key=True, index=True)
    survey_number = Column(String(60), unique=True, index=True, nullable=False)
    district = Column(String(100))
    taluk = Column(String(100))
    village = Column(String(100))
    area_sqft = Column(Float)
    property_type = Column(String(50))  # residential, agricultural, commercial
    current_owner = Column(String(150))
    patta_number = Column(String(60))
    chitta_number = Column(String(60))
    market_value_est = Column(Float, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    owners = relationship("OwnershipRecord", back_populates="property", cascade="all, delete-orphan")
    encumbrances = relationship("Encumbrance", back_populates="property", cascade="all, delete-orphan")
    court_cases = relationship("CourtCase", back_populates="property", cascade="all, delete-orphan")


class OwnershipRecord(Base):
    __tablename__ = "ownership_records"
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"))
    owner_name = Column(String(150))
    acquisition_type = Column(String(80))  # sale, inheritance, gift, partition
    document_number = Column(String(80))
    registration_date = Column(DateTime)
    registrar_office = Column(String(120))
    sale_amount = Column(Float, nullable=True)

    property = relationship("Property", back_populates="owners")


class Encumbrance(Base):
    __tablename__ = "encumbrances"
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"))
    encumbrance_type = Column(String(80))  # mortgage, lien, lease, dispute
    holder_name = Column(String(150))
    amount = Column(Float, nullable=True)
    status = Column(String(30), default="active")  # active, cleared
    created_date = Column(DateTime, default=datetime.utcnow)

    property = relationship("Property", back_populates="encumbrances")


class CourtCase(Base):
    __tablename__ = "court_cases"
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"))
    case_number = Column(String(80))
    court_name = Column(String(150))
    case_type = Column(String(80))  # title dispute, partition, injunction, criminal
    status = Column(String(40), default="pending")  # pending, disposed, stayed
    filed_date = Column(DateTime)
    last_hearing_date = Column(DateTime, nullable=True)
    next_hearing_date = Column(DateTime, nullable=True)
    summary = Column(Text)
    severity_weight = Column(Float, default=0.5)  # 0-1, used by risk engine

    property = relationship("Property", back_populates="court_cases")


class Alert(Base):
    __tablename__ = "alerts"
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"))
    message = Column(Text)
    severity = Column(String(20), default="info")  # info, warning, critical
    created_at = Column(DateTime, default=datetime.utcnow)
    is_read = Column(Boolean, default=False)


class VerificationReport(Base):
    __tablename__ = "verification_reports"
    id = Column(Integer, primary_key=True, index=True)
    property_id = Column(Integer, ForeignKey("properties.id"))
    generated_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    risk_score = Column(Float)
    risk_level = Column(String(20))
    file_path = Column(String(255))
    created_at = Column(DateTime, default=datetime.utcnow)
