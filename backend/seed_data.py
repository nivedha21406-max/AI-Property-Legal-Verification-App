"""
Populates the database with realistic sample data so the app is immediately
usable / demoable. Run with:  python seed_data.py
"""
from datetime import datetime, timedelta
from app.database import SessionLocal, engine, Base
from app import models, auth

Base.metadata.create_all(bind=engine)
db = SessionLocal()


def run():
    if db.query(models.Property).count() > 0:
        print("Database already seeded. Delete property_verification.db to reseed.")
        return

    # ---- Demo user ----
    demo_user = models.User(
        full_name="Demo Buyer",
        email="demo@example.com",
        hashed_password=auth.get_password_hash("password123"),
        role="buyer",
    )
    db.add(demo_user)

    properties_data = [
        dict(survey_number="123/4A", district="Chennai", taluk="Egmore", village="Nungambakkam",
             area_sqft=2400, property_type="residential", current_owner="R. Kumaresan",
             patta_number="P-88231", chitta_number="C-44120", market_value_est=9500000),
        dict(survey_number="45/2", district="Coimbatore", taluk="Peelamedu", village="Ganapathy",
             area_sqft=5200, property_type="commercial", current_owner="S. Priya Traders Pvt Ltd",
             patta_number="P-11029", chitta_number="C-98771", market_value_est=18000000),
        dict(survey_number="78/1B", district="Madurai", taluk="Melur", village="Alanganallur",
             area_sqft=43000, property_type="agricultural", current_owner="M. Selvam",
             patta_number="P-30044", chitta_number="C-30044", market_value_est=6200000),
        dict(survey_number="200/9", district="Chennai", taluk="Ambattur", village="Padi",
             area_sqft=1800, property_type="residential", current_owner="A. Fathima",
             patta_number="P-77102", chitta_number="C-19983", market_value_est=7200000),
        dict(survey_number="15/3C", district="Trichy", taluk="Srirangam", village="Thiruvanaikoil",
             area_sqft=3100, property_type="residential", current_owner="V. Rajasekaran",
             patta_number="P-55210", chitta_number="C-10098", market_value_est=5400000),
    ]

    props = []
    for pdata in properties_data:
        p = models.Property(**pdata)
        db.add(p)
        props.append(p)
    db.commit()
    for p in props:
        db.refresh(p)

    # ---- Ownership history ----
    db.add_all([
        models.OwnershipRecord(property_id=props[0].id, owner_name="K. Balasubramaniam",
                                acquisition_type="sale", document_number="DOC-2010-3321",
                                registration_date=datetime(2010, 6, 12), registrar_office="Egmore SRO", sale_amount=3200000),
        models.OwnershipRecord(property_id=props[0].id, owner_name="R. Kumaresan",
                                acquisition_type="sale", document_number="DOC-2021-8842",
                                registration_date=datetime(2021, 3, 4), registrar_office="Egmore SRO", sale_amount=8600000),

        models.OwnershipRecord(property_id=props[1].id, owner_name="S. Priya Traders Pvt Ltd",
                                acquisition_type="sale", document_number="DOC-2019-1140",
                                registration_date=datetime(2019, 11, 20), registrar_office="Peelamedu SRO", sale_amount=15000000),

        models.OwnershipRecord(property_id=props[2].id, owner_name="M. Selvam",
                                acquisition_type="inheritance", document_number="DOC-2005-0099",
                                registration_date=datetime(2005, 1, 15), registrar_office="Melur SRO", sale_amount=None),

        # Rapid-flip pattern to trigger fraud heuristic
        models.OwnershipRecord(property_id=props[3].id, owner_name="J. Anbu",
                                acquisition_type="sale", document_number="DOC-2024-5510",
                                registration_date=datetime(2024, 1, 10), registrar_office="Ambattur SRO", sale_amount=5000000),
        models.OwnershipRecord(property_id=props[3].id, owner_name="A. Fathima",
                                acquisition_type="sale", document_number="DOC-2024-5990",
                                registration_date=datetime(2024, 3, 22), registrar_office="Ambattur SRO", sale_amount=7100000),

        models.OwnershipRecord(property_id=props[4].id, owner_name="V. Rajasekaran",
                                acquisition_type="gift", document_number="DOC-2016-2207",
                                registration_date=datetime(2016, 8, 30), registrar_office="Srirangam SRO", sale_amount=None),
    ])

    # ---- Encumbrances ----
    db.add_all([
        models.Encumbrance(property_id=props[0].id, encumbrance_type="mortgage", holder_name="HDFC Bank",
                            amount=4500000, status="active"),
        models.Encumbrance(property_id=props[1].id, encumbrance_type="lien", holder_name="SBI Bank",
                            amount=16000000, status="active"),
        models.Encumbrance(property_id=props[3].id, encumbrance_type="dispute", holder_name="J. Anbu (previous owner)",
                            amount=None, status="active"),
        models.Encumbrance(property_id=props[4].id, encumbrance_type="mortgage", holder_name="Canara Bank",
                            amount=1200000, status="cleared"),
    ])

    # ---- Court cases ----
    db.add_all([
        models.CourtCase(property_id=props[1].id, case_number="OS/442/2023", court_name="Coimbatore District Court",
                          case_type="Title Dispute", status="pending", filed_date=datetime(2023, 7, 18),
                          last_hearing_date=datetime(2026, 5, 10), next_hearing_date=datetime(2026, 9, 2),
                          summary="Dispute over boundary demarcation and validity of 2019 sale deed raised by adjacent landowner.",
                          severity_weight=0.85),
        models.CourtCase(property_id=props[3].id, case_number="CS/119/2024", court_name="Chennai City Civil Court",
                          case_type="Title Dispute", status="pending", filed_date=datetime(2024, 4, 2),
                          last_hearing_date=datetime(2026, 6, 15), next_hearing_date=datetime(2026, 10, 20),
                          summary="Previous owner J. Anbu contests validity of March 2024 sale, alleging coercion.",
                          severity_weight=0.9),
        models.CourtCase(property_id=props[2].id, case_number="LA/77/2021", court_name="Madurai Revenue Court",
                          case_type="Partition", status="disposed", filed_date=datetime(2021, 2, 11),
                          last_hearing_date=datetime(2022, 9, 30), next_hearing_date=None,
                          summary="Family partition suit among legal heirs, resolved via consent decree in 2022.",
                          severity_weight=0.3),
        models.CourtCase(property_id=props[4].id, case_number="INJ/205/2025", court_name="Trichy District Court",
                          case_type="Injunction", status="pending", filed_date=datetime(2025, 9, 5),
                          last_hearing_date=datetime(2026, 4, 1), next_hearing_date=datetime(2026, 11, 5),
                          summary="Temporary injunction sought by neighbor regarding shared access pathway.",
                          severity_weight=0.4),
    ])

    # ---- Alerts ----
    db.add_all([
        models.Alert(property_id=props[1].id, message="New hearing scheduled for OS/442/2023 on 2026-09-02", severity="warning"),
        models.Alert(property_id=props[3].id, message="High-risk title dispute active — CS/119/2024", severity="critical"),
    ])

    db.commit()
    print("✅ Seed data inserted successfully.")
    print("Demo login -> email: demo@example.com | password: password123")
    print("Try survey numbers: 123/4A, 45/2, 78/1B, 200/9, 15/3C")


if __name__ == "__main__":
    run()
