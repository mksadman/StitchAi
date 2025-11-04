"""
Lightweight AI recommender stub.

This implementation avoids heavy dependencies and provides a simple
attribute-based scoring mechanism. It can later be replaced by a more
advanced model without changing the contract.

Contract:
- Inputs:
  - user_input: dict (e.g., {"clothing_type": str, "material": [str], "color": [str], "pattern": str, "style": str})
  - fabric_list: list[dict] with keys: fabric_id, name, material, color, pattern, price, stock, supplier_id
- Output: list[str] of fabric_id ranked by relevance
"""
from typing import Dict, List, Any


def _normalize(value: Any) -> str:
    return str(value).strip().lower() if value is not None else ""


def _tokenize(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [_normalize(v) for v in value if v is not None]
    # support comma/space separated entries
    txt = _normalize(value)
    if not txt:
        return []
    # split on comma first, then spaces for multi-word colors/materials stay intact otherwise
    parts = [p.strip() for chunk in txt.split(',') for p in [chunk] if p]
    return parts if parts else [txt]


def recommend_fabrics(user_input: Dict[str, Any], fabric_list: List[Dict[str, Any]], top_n: int = 12) -> List[str]:
    desired_materials = set(_tokenize(user_input.get("material")))
    desired_colors = set(_tokenize(user_input.get("color")))
    desired_pattern = _normalize(user_input.get("pattern"))

    def score(f: Dict[str, Any]) -> float:
        s = 0.0
        # material match (any overlap)
        fabric_materials = set(_tokenize(f.get("material")))
        if desired_materials:
            overlap = desired_materials.intersection(fabric_materials)
            if overlap:
                s += 3.0
        # color match (any overlap)
        fabric_colors = set(_tokenize(f.get("color")))
        if desired_colors:
            overlap = desired_colors.intersection(fabric_colors)
            if overlap:
                s += 2.0
        # pattern match (exact, case-insensitive)
        if desired_pattern and _normalize(f.get("pattern")) == desired_pattern:
            s += 1.5
        # availability boost
        try:
            if int(f.get("stock", 0)) > 0:
                s += 0.25
        except Exception:
            pass
        return s

    ranked = sorted(fabric_list, key=score, reverse=True)
    # Filter out items with zero score if user specified constraints
    has_constraints = bool(desired_materials or desired_colors or desired_pattern)
    if has_constraints:
        ranked = [f for f in ranked if score(f) > 0]

    top = ranked[:top_n]
    return [str(f["fabric_id"]) for f in top]
