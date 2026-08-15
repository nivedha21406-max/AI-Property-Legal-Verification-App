import os
from datetime import datetime

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor
from reportlab.pdfgen import canvas

from .. import models

NAVY = HexColor("#0B1F3A")
GOLD = HexColor("#C9A227")
GREY = HexColor("#444444")

REPORTS_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "generated_reports")
os.makedirs(REPORTS_DIR, exist_ok=True)


def generate_verification_report(prop: models.Property, risk: dict) -> str:
    filename = f"verification_report_{prop.survey_number.replace('/', '_')}_{int(datetime.utcnow().timestamp())}.pdf"
    filepath = os.path.join(REPORTS_DIR, filename)

    c = canvas.Canvas(filepath, pagesize=A4)
    width, height = A4
    y = height - 25 * mm

    # Header bar
    c.setFillColor(NAVY)
    c.rect(0, height - 22 * mm, width, 22 * mm, fill=1, stroke=0)
    c.setFillColor(GOLD)
    c.setFont("Helvetica-Bold", 16)
    c.drawString(15 * mm, height - 14 * mm, "PROPERTY VERIFICATION REPORT")
    c.setFillColor(HexColor("#FFFFFF"))
    c.setFont("Helvetica", 9)
    c.drawString(15 * mm, height - 19 * mm, "AI Property Legal Verification & Litigation Risk Assessment System")

    y = height - 30 * mm
    c.setFillColor(GREY)
    c.setFont("Helvetica", 9)
    c.drawRightString(width - 15 * mm, y, f"Generated: {datetime.utcnow().strftime('%d-%b-%Y %H:%M UTC')}")
    y -= 12 * mm

    def section_title(text, y):
        c.setFillColor(NAVY)
        c.setFont("Helvetica-Bold", 12)
        c.drawString(15 * mm, y, text)
        c.setStrokeColor(GOLD)
        c.line(15 * mm, y - 2 * mm, width - 15 * mm, y - 2 * mm)
        return y - 8 * mm

    def kv(label, value, y):
        c.setFillColor(GREY)
        c.setFont("Helvetica-Bold", 9)
        c.drawString(18 * mm, y, f"{label}:")
        c.setFont("Helvetica", 9)
        c.drawString(60 * mm, y, str(value))
        return y - 6 * mm

    y = section_title("Property Details", y)
    y = kv("Survey Number", prop.survey_number, y)
    y = kv("Location", f"{prop.village}, {prop.taluk}, {prop.district}", y)
    y = kv("Property Type", prop.property_type, y)
    y = kv("Area (sq ft)", prop.area_sqft, y)
    y = kv("Current Owner", prop.current_owner, y)
    y = kv("Patta / Chitta No.", f"{prop.patta_number} / {prop.chitta_number}", y)
    y -= 4 * mm

    y = section_title("AI Litigation Risk Assessment", y)
    level_color = NAVY
    if risk["risk_level"] == "HIGH":
        level_color = HexColor("#B3261E")
    elif risk["risk_level"] == "MEDIUM":
        level_color = HexColor("#B26A00")
    else:
        level_color = HexColor("#1B7A3D")

    c.setFillColor(level_color)
    c.setFont("Helvetica-Bold", 20)
    c.drawString(18 * mm, y, f"{risk['risk_score']} / 100")
    c.setFont("Helvetica-Bold", 12)
    c.drawString(70 * mm, y + 2, f"RISK LEVEL: {risk['risk_level']}")
    y -= 10 * mm

    c.setFillColor(GREY)
    c.setFont("Helvetica", 9)
    c.drawString(18 * mm, y, f"Active court cases: {risk['active_cases']}   |   Active encumbrances: {risk['active_encumbrances']}")
    y -= 8 * mm

    c.setFont("Helvetica-Bold", 9)
    c.drawString(18 * mm, y, "Risk Factors:")
    y -= 6 * mm
    c.setFont("Helvetica", 8.5)
    for factor in risk["factors"][:12]:
        for line in _wrap_text(factor, 95):
            c.drawString(20 * mm, y, f"- {line}")
            y -= 5 * mm
    y -= 3 * mm

    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(NAVY)
    c.drawString(18 * mm, y, "Recommendation:")
    y -= 6 * mm
    c.setFillColor(GREY)
    c.setFont("Helvetica", 9)
    for line in _wrap_text(risk["recommendation"], 95):
        c.drawString(18 * mm, y, line)
        y -= 5 * mm

    y -= 8 * mm
    c.setFont("Helvetica-Oblique", 7.5)
    c.setFillColor(HexColor("#888888"))
    c.drawString(15 * mm, y, "Disclaimer: Auto-generated using available system records. Not a substitute for certified legal title verification.")

    c.showPage()
    c.save()
    return filepath


def _wrap_text(text, width):
    words = text.split()
    lines, current = [], ""
    for w in words:
        if len(current) + len(w) + 1 <= width:
            current = f"{current} {w}".strip()
        else:
            lines.append(current)
            current = w
    if current:
        lines.append(current)
    return lines
