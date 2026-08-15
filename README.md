# AI Property Legal Verification & Litigation Risk Assessment System

Full-stack project: **FastAPI backend** (AI risk engine, NLP extraction, PDF
reports, real-time WebSocket alerts) + **Flutter mobile app** (professional
navy & gold legal-tech theme).

```
project/
├── backend/          FastAPI + SQLAlchemy + AI/NLP services
└── mobile_app/        Flutter app (Android/iOS)
```

## ⚠️ Important — what's real vs. what's simulated

This was built from your abstract, which references live integration with
government portals (Patta/Chitta, TNREGINET, eCourts). Those systems have
**no public APIs**, so this project ships with:

- A fully working backend, database schema, AI risk-scoring engine, NLP
  extractor, fraud-flag heuristics, and PDF report generator — all real,
  running code, tested end-to-end.
- **Realistic seed/demo data** (5 sample properties with ownership chains,
  encumbrances, and court cases) standing in for live portal data.
- To go from demo → production you'd need to either get official data-sharing
  agreements with TNREGINET/eCourts/registration departments, or build
  scrapers against their public search pages (check each site's terms of use
  first) and feed that data into the `properties`, `ownership_records`,
  `encumbrances`, and `court_cases` tables via the existing `/api/properties`
  and `/api/litigation/cases` endpoints.

Everything else — search, risk scoring, fraud flags, document AI extraction,
PDF reports, real-time alerts, comparison, mobile UI — is fully functional
right now.

---

## 1. Backend Setup (VS Code)

**Requirements:** Python 3.10+

```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Seed the database with demo data
python seed_data.py

# Run the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API docs (Swagger UI): **http://localhost:8000/docs**
- Demo login: `demo@example.com` / `password123`
- Demo survey numbers to search: `123/4A`, `45/2`, `78/1B`, `200/9`, `15/3C`

### Switching to MySQL (as described in your abstract)

By default the app uses SQLite (zero setup, works instantly). To use MySQL:

1. Create a database: `CREATE DATABASE property_verification;`
2. Create a `.env` file in `backend/`:
   ```
   DATABASE_URL=mysql+pymysql://youruser:yourpassword@localhost:3306/property_verification
   SECRET_KEY=replace-with-a-long-random-string
   ```
3. Re-run `python seed_data.py` — tables and seed data will be created in MySQL.

---

## 2. Mobile App Setup (VS Code + Flutter)

**Requirements:** Flutter SDK 3.x installed ([flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install))

```bash
cd mobile_app
flutter pub get
```

### Point the app at your backend

Edit `mobile_app/lib/services/api_service.dart`:

```dart
static String baseUrl = "http://10.0.2.2:8000";   // Android emulator (default)
// static String baseUrl = "http://127.0.0.1:8000";  // iOS simulator
// static String baseUrl = "http://192.168.1.X:8000"; // physical device — use your computer's LAN IP
```

Run it:

```bash
flutter run
```

Or open the `mobile_app` folder directly in VS Code with the Flutter extension
installed, select a device/emulator, and press **F5**.

---

## 3. What's implemented

**Backend**
- JWT auth (roles: buyer / seller / bank / lawyer)
- Survey-number search → full ownership + encumbrance + litigation record
- AI Litigation Risk Score (explainable, weighted scoring engine)
- NLP document extraction (survey no. / patta no. / dates / entities from pasted text)
- Fraud-flag heuristics (over-encumbrance, ownership mismatch, disputed+mortgaged)
- Branded PDF verification report generation & download
- Real-time alerts via WebSocket (`/ws/alerts`) + REST alert feed
- Property comparison endpoint

**Mobile app**
- Splash → Login/Register → bottom-nav shell (Dashboard, Search, Alerts, Profile)
- Dashboard with quick actions + recently tracked properties
- Search by survey number
- Property detail: animated risk gauge, risk factors, fraud flags, ownership
  history, encumbrances, court case timeline, one-tap PDF report download
- AI Document Extraction screen (paste deed/court text → auto-extracted entities → linked property)
- Side-by-side property comparison
- Real-time litigation alerts (WebSocket live feed + history)
- Professional navy & gold theme throughout

## 4. Next steps to extend

- Swap the rule-based risk engine (`backend/app/services/risk_engine.py`) for
  a trained ML model once you have historical case-outcome data.
- Swap the regex-based NLP extractor for spaCy/a transformer NER model for
  more robust entity extraction from scanned/OCR'd documents.
- Add real document upload (currently text-paste only) with OCR pre-processing.
- Add push notifications (FCM) for the mobile alerts instead of/alongside WebSocket.
