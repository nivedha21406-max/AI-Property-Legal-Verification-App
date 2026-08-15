from fastapi import APIRouter, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

from .. import models, schemas, auth
from ..database import get_db
from ..websocket_manager import manager

router = APIRouter(tags=["Alerts / Real-time"])


@router.get("/api/alerts", response_model=list[schemas.AlertOut])
def list_alerts(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user), limit: int = 50):
    # Get all properties and their alerts for the current user
    alerts = (
        db.query(models.Alert)
        .join(models.Property)
        .filter(models.Alert.property_id == models.Property.id)
        .order_by(models.Alert.created_at.desc())
        .limit(limit)
        .all()
    )
    return alerts


@router.patch("/api/alerts/{alert_id}/read")
def mark_read(alert_id: int, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    alert = db.query(models.Alert).filter(models.Alert.id == alert_id).first()
    if alert:
        alert.is_read = True
        db.commit()
    return {"ok": True}


@router.websocket("/ws/alerts")
async def websocket_alerts(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()  # keep-alive / client pings
    except WebSocketDisconnect:
        manager.disconnect(websocket)
