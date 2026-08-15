from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db
from ..websocket_manager import manager

router = APIRouter(prefix="/api/litigation", tags=["Litigation / Court Cases"])


@router.get("/timeline", response_model=list[schemas.CourtCaseOut])
def case_timeline(survey_number: str, db: Session = Depends(get_db)):
    prop = db.query(models.Property).filter(models.Property.survey_number == survey_number).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found")
    cases = sorted(prop.court_cases, key=lambda c: c.filed_date or c.filed_date)
    return cases


@router.post("/cases", response_model=schemas.CourtCaseOut)
async def add_court_case(payload: schemas.CourtCaseCreate, db: Session = Depends(get_db)):
    prop = db.query(models.Property).filter(models.Property.survey_number == payload.survey_number).first()
    if not prop:
        raise HTTPException(status_code=404, detail="Property not found for given survey number")

    case = models.CourtCase(
        property_id=prop.id,
        case_number=payload.case_number,
        court_name=payload.court_name,
        case_type=payload.case_type,
        status=payload.status,
        filed_date=payload.filed_date,
        summary=payload.summary,
        severity_weight=payload.severity_weight,
    )
    db.add(case)

    alert = models.Alert(
        property_id=prop.id,
        message=f"New {payload.case_type} case ({payload.case_number}) filed for survey no. {prop.survey_number}",
        severity="critical" if payload.severity_weight > 0.6 else "warning",
    )
    db.add(alert)
    db.commit()
    db.refresh(case)

    await manager.broadcast({
        "type": "new_litigation_alert",
        "survey_number": prop.survey_number,
        "message": alert.message,
        "severity": alert.severity,
    })
    return case
