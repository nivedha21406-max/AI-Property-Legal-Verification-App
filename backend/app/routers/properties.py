from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload

from .. import models, schemas
from ..database import get_db

router = APIRouter(prefix="/api/properties", tags=["Properties"])


def _with_relations(db: Session):
    return db.query(models.Property).options(
        joinedload(models.Property.owners),
        joinedload(models.Property.encumbrances),
        joinedload(models.Property.court_cases),
    )


@router.get("/search", response_model=schemas.PropertyDetail)
def search_by_survey_number(survey_number: str = Query(...), db: Session = Depends(get_db)):
    prop = _with_relations(db).filter(models.Property.survey_number == survey_number).first()
    if not prop:
        raise HTTPException(status_code=404, detail=f"No property found for survey number '{survey_number}'")
    return prop


@router.get("", response_model=List[schemas.PropertyOut])
def list_properties(
    district: Optional[str] = None,
    property_type: Optional[str] = None,
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    query = db.query(models.Property)
    if district:
        query = query.filter(models.Property.district == district)
    if property_type:
        query = query.filter(models.Property.property_type == property_type)
    return query.offset(skip).limit(limit).all()


@router.get("/{property_id}", response_model=schemas.PropertyDetail)
def get_property(property_id: int, db: Session = Depends(get_db)):
    prop = _with_relations(db).filter(models.Property.id == property_id).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
    return prop


@router.post("", response_model=schemas.PropertyOut)
def create_property(payload: schemas.PropertyCreate, db: Session = Depends(get_db)):
    existing = db.query(models.Property).filter(models.Property.survey_number == payload.survey_number).first()
    if existing:
        raise HTTPException(status_code=400, detail="Property with this survey number already exists")
    prop = models.Property(**payload.dict())
    db.add(prop)
    db.commit()
    db.refresh(prop)
    return prop


@router.post("/compare", response_model=List[schemas.PropertyDetail])
def compare_properties(payload: schemas.ComparisonRequest, db: Session = Depends(get_db)):
    if len(payload.survey_numbers) < 2:
        raise HTTPException(status_code=400, detail="Provide at least 2 survey numbers to compare")
    props = _with_relations(db).filter(models.Property.survey_number.in_(payload.survey_numbers)).all()
    return props
