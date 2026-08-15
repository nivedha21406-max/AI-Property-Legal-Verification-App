from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List


# ---------- Auth ----------
class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: str = "buyer"


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    role: str

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ---------- Ownership ----------
class OwnershipOut(BaseModel):
    id: int
    owner_name: str
    acquisition_type: str
    document_number: str
    registration_date: Optional[datetime]
    registrar_office: Optional[str]
    sale_amount: Optional[float]

    class Config:
        from_attributes = True


# ---------- Encumbrance ----------
class EncumbranceOut(BaseModel):
    id: int
    encumbrance_type: str
    holder_name: str
    amount: Optional[float]
    status: str
    created_date: datetime

    class Config:
        from_attributes = True


# ---------- Court Case ----------
class CourtCaseOut(BaseModel):
    id: int
    case_number: str
    court_name: str
    case_type: str
    status: str
    filed_date: Optional[datetime]
    last_hearing_date: Optional[datetime]
    next_hearing_date: Optional[datetime]
    summary: Optional[str]
    severity_weight: float

    class Config:
        from_attributes = True


class CourtCaseCreate(BaseModel):
    survey_number: str
    case_number: str
    court_name: str
    case_type: str
    status: str = "pending"
    filed_date: datetime
    summary: str
    severity_weight: float = 0.5


# ---------- Property ----------
class PropertyOut(BaseModel):
    id: int
    survey_number: str
    district: Optional[str]
    taluk: Optional[str]
    village: Optional[str]
    area_sqft: Optional[float]
    property_type: Optional[str]
    current_owner: Optional[str]
    patta_number: Optional[str]
    chitta_number: Optional[str]
    market_value_est: Optional[float]

    class Config:
        from_attributes = True


class PropertyDetail(PropertyOut):
    owners: List[OwnershipOut] = []
    encumbrances: List[EncumbranceOut] = []
    court_cases: List[CourtCaseOut] = []


class PropertyCreate(BaseModel):
    survey_number: str
    district: str
    taluk: str
    village: str
    area_sqft: float
    property_type: str
    current_owner: str
    patta_number: str
    chitta_number: str
    market_value_est: float = 0


# ---------- Risk / AI ----------
class RiskAssessmentOut(BaseModel):
    survey_number: str
    risk_score: float
    risk_level: str
    factors: List[str]
    active_cases: int
    active_encumbrances: int
    recommendation: str


class DocumentExtractionRequest(BaseModel):
    document_text: str


class DocumentExtractionOut(BaseModel):
    survey_numbers_found: List[str]
    patta_numbers_found: List[str]
    dates_found: List[str]
    entities: List[str]
    matched_properties: List[PropertyOut]


class ComparisonRequest(BaseModel):
    survey_numbers: List[str]


class AlertOut(BaseModel):
    id: int
    property_id: int
    message: str
    severity: str
    created_at: datetime
    is_read: bool

    class Config:
        from_attributes = True
