"""
NLP-based document extraction.

Uses regex-based pattern extraction tuned for Indian land-record / court-document
conventions (Survey No., Patta No., dates) plus lightweight named-entity heuristics.

This is dependency-light by design so it runs anywhere without heavy NLP model
downloads. Swap in spaCy / a transformer NER model here later for production-grade
entity extraction — the function signature stays the same.
"""
import re
from typing import List

SURVEY_NO_PATTERNS = [
    r"[Ss]urvey\s*(?:No|Number|#)\.?\s*[:\-]?\s*([A-Za-z0-9/\-]+)",
    r"S\.?\s*No\.?\s*[:\-]?\s*([A-Za-z0-9/\-]+)",
]

PATTA_NO_PATTERNS = [
    r"[Pp]atta\s*(?:No|Number|#)\.?\s*[:\-]?\s*([A-Za-z0-9/\-]+)",
]

DATE_PATTERN = r"\b(\d{1,2}[/\-.]\d{1,2}[/\-.]\d{2,4}|\d{4}-\d{2}-\d{2})\b"

# Very lightweight entity heuristic: capitalized multi-word sequences,
# excluding common legal boilerplate words.
ENTITY_PATTERN = r"\b(?:[A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})\b"
STOPWORDS = {"The Court", "High Court", "District Court", "In Re", "This Deed"}


def extract_survey_numbers(text: str) -> List[str]:
    found = set()
    for pattern in SURVEY_NO_PATTERNS:
        for match in re.finditer(pattern, text):
            found.add(match.group(1).strip("."))
    return sorted(found)


def extract_patta_numbers(text: str) -> List[str]:
    found = set()
    for pattern in PATTA_NO_PATTERNS:
        for match in re.finditer(pattern, text):
            found.add(match.group(1).strip("."))
    return sorted(found)


def extract_dates(text: str) -> List[str]:
    return sorted(set(re.findall(DATE_PATTERN, text)))


def extract_entities(text: str) -> List[str]:
    candidates = set(re.findall(ENTITY_PATTERN, text))
    return sorted(c for c in candidates if c not in STOPWORDS)


def extract_all(text: str) -> dict:
    return {
        "survey_numbers_found": extract_survey_numbers(text),
        "patta_numbers_found": extract_patta_numbers(text),
        "dates_found": extract_dates(text),
        "entities": extract_entities(text),
    }
