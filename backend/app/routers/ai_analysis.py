from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from .. import models, schemas
from ..database import get_db
from ..services import risk_engine, nlp_extractor

router = APIRouter(prefix="/api/ai", tags=["AI Analysis"])


def _get_full_property(db: Session, survey_number: str) -> models.Property:
    prop = (
        db.query(models.Property)
        .options(
            joinedload(models.Property.owners),
            joinedload(models.Property.encumbrances),
            joinedload(models.Property.court_cases),
        )
        .filter(models.Property.survey_number == survey_number)
        .first()
    )
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
    return prop


@router.get("/risk-score", response_model=schemas.RiskAssessmentOut)
def risk_score(survey_number: str, db: Session = Depends(get_db)):
    prop = _get_full_property(db, survey_number)
    return risk_engine.assess_property_risk(prop)


@router.post("/extract-document", response_model=schemas.DocumentExtractionOut)
def extract_document(payload: schemas.DocumentExtractionRequest, db: Session = Depends(get_db)):
    extracted = nlp_extractor.extract_all(payload.document_text)
    matched = []
    if extracted["survey_numbers_found"]:
        matched = (
            db.query(models.Property)
            .filter(models.Property.survey_number.in_(extracted["survey_numbers_found"]))
            .all()
        )
    return {**extracted, "matched_properties": matched}


@router.get("/fraud-flags")
def fraud_flags(survey_number: str, db: Session = Depends(get_db)):
    prop = _get_full_property(db, survey_number)
    flags = []

    # Heuristic 1: multiple active liens/mortgages exceeding market value
    total_encumbered = sum(e.amount or 0 for e in prop.encumbrances if e.status == "active")
    if prop.market_value_est and total_encumbered > prop.market_value_est * 0.8:
        flags.append({
            "flag": "OVER_ENCUMBERED",
            "detail": f"Active encumbrances (₹{total_encumbered:,.0f}) exceed 80% of estimated market value (₹{prop.market_value_est:,.0f})",
        })

    # Heuristic 2: ownership name mismatch between current_owner and latest registration record
    if prop.owners:
        latest = sorted([o for o in prop.owners if o.registration_date], key=lambda o: o.registration_date, reverse=True)
        if latest and prop.current_owner and latest[0].owner_name.strip().lower() != prop.current_owner.strip().lower():
            flags.append({
                "flag": "OWNERSHIP_MISMATCH",
                "detail": f"Registered owner ('{latest[0].owner_name}') differs from current listed owner ('{prop.current_owner}')",
            })

    # Heuristic 3: active title-dispute case combined with active mortgage
    has_title_dispute = any(c.case_type.lower() == "title dispute" and c.status == "pending" for c in prop.court_cases)
    has_mortgage = any(e.encumbrance_type.lower() == "mortgage" and e.status == "active" for e in prop.encumbrances)
    if has_title_dispute and has_mortgage:
        flags.append({
            "flag": "DISPUTED_TITLE_MORTGAGED",
            "detail": "Property under active title dispute is also currently mortgaged — high fraud/foreclosure risk",
        })

    return {"survey_number": survey_number, "fraud_flags": flags, "flag_count": len(flags)}
