import os
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session, joinedload

from .. import models
from ..database import get_db
from ..services import risk_engine, report_generator

router = APIRouter(prefix="/api/reports", tags=["Verification Reports"])


@router.post("/generate")
def generate_report(survey_number: str, db: Session = Depends(get_db)):
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

    risk = risk_engine.assess_property_risk(prop)
    filepath = report_generator.generate_verification_report(prop, risk)

    record = models.VerificationReport(
        property_id=prop.id,
        risk_score=risk["risk_score"],
        risk_level=risk["risk_level"],
        file_path=filepath,
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    return {"report_id": record.id, "download_url": f"/api/reports/download/{record.id}", "risk": risk}


@router.get("/download/{report_id}")
def download_report(report_id: int, db: Session = Depends(get_db)):
    record = db.query(models.VerificationReport).filter(models.VerificationReport.id == report_id).first()
    if not record or not os.path.exists(record.file_path):
        raise HTTPException(status_code=404, detail="Report not found")
    return FileResponse(record.file_path, media_type="application/pdf", filename=os.path.basename(record.file_path))
