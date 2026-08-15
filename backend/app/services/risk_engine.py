"""
AI-based Litigation Risk Scoring Engine.

This module computes an explainable risk score (0-100) for a property based on:
  - number & severity of active court cases
  - number & value of active encumbrances (mortgages, liens)
  - ownership chain irregularities (gaps, too many transfers in short time)
  - case type severity weighting (title disputes weigh more than minor injunctions)

Designed so the weighting logic can later be swapped for a trained ML model
(e.g. gradient boosting on historical case-outcome data) without changing the
API contract — `assess_property_risk` is the single entry point consumers use.
"""
from datetime import datetime
from typing import List, Tuple

from .. import models

CASE_TYPE_BASE_WEIGHT = {
    "title dispute": 30,
    "partition": 18,
    "injunction": 12,
    "criminal": 25,
    "revenue dispute": 15,
    "tax default": 10,
}

ENCUMBRANCE_WEIGHT = {
    "mortgage": 8,
    "lien": 12,
    "lease": 4,
    "dispute": 20,
}


def _score_court_cases(cases: List[models.CourtCase]) -> Tuple[float, List[str]]:
    score = 0.0
    factors = []
    active = [c for c in cases if c.status.lower() == "pending"]
    for case in active:
        base = CASE_TYPE_BASE_WEIGHT.get(case.case_type.lower(), 10)
        weighted = base * max(case.severity_weight, 0.1)
        score += weighted
        factors.append(
            f"Active {case.case_type} case ({case.case_number}) in {case.court_name} "
            f"contributes +{weighted:.1f} risk points"
        )
    if len(active) >= 3:
        score += 10
        factors.append("Multiple simultaneous active cases increase compounded risk (+10)")
    return score, factors


def _score_encumbrances(encumbrances: List[models.Encumbrance]) -> Tuple[float, List[str]]:
    score = 0.0
    factors = []
    active = [e for e in encumbrances if e.status.lower() == "active"]
    for enc in active:
        weight = ENCUMBRANCE_WEIGHT.get(enc.encumbrance_type.lower(), 6)
        score += weight
        factors.append(f"Active {enc.encumbrance_type} held by {enc.holder_name} contributes +{weight} risk points")
    return score, factors


def _score_ownership_chain(owners: List[models.OwnershipRecord]) -> Tuple[float, List[str]]:
    score = 0.0
    factors = []
    if len(owners) == 0:
        score += 15
        factors.append("No ownership registration history found — unverifiable title chain (+15)")
        return score, factors

    sorted_owners = sorted([o for o in owners if o.registration_date], key=lambda o: o.registration_date)
    if len(sorted_owners) >= 2:
        for i in range(1, len(sorted_owners)):
            gap_days = (sorted_owners[i].registration_date - sorted_owners[i - 1].registration_date).days
            if 0 <= gap_days < 180:
                score += 8
                factors.append(
                    f"Rapid ownership transfer within {gap_days} days "
                    f"({sorted_owners[i-1].owner_name} -> {sorted_owners[i].owner_name}) — possible flip/fraud pattern (+8)"
                )
    return score, factors


def assess_property_risk(prop: models.Property) -> dict:
    case_score, case_factors = _score_court_cases(prop.court_cases)
    enc_score, enc_factors = _score_encumbrances(prop.encumbrances)
    chain_score, chain_factors = _score_ownership_chain(prop.owners)

    raw_score = case_score + enc_score + chain_score
    # Normalize to 0-100 using a soft cap
    risk_score = min(100.0, raw_score)

    if risk_score >= 60:
        level = "HIGH"
        recommendation = "High legal risk detected. Strongly recommend independent legal counsel and title search before purchase."
    elif risk_score >= 30:
        level = "MEDIUM"
        recommendation = "Moderate risk factors present. Review flagged cases/encumbrances and obtain an encumbrance certificate before proceeding."
    else:
        level = "LOW"
        recommendation = "No major red flags detected in available records. Standard due diligence still advised."

    factors = case_factors + enc_factors + chain_factors
    if not factors:
        factors = ["No active litigation, encumbrances, or ownership irregularities found in records."]

    return {
        "survey_number": prop.survey_number,
        "risk_score": round(risk_score, 1),
        "risk_level": level,
        "factors": factors,
        "active_cases": len([c for c in prop.court_cases if c.status.lower() == "pending"]),
        "active_encumbrances": len([e for e in prop.encumbrances if e.status.lower() == "active"]),
        "recommendation": recommendation,
    }
