"""
Lightweight AI recommender with ML fallback.

Two-tier approach:
- Preferred: Content-based ranking using scikit-learn (TF-IDF + cosine similarity)
- Fallback: Simple attribute-based scoring when ML stack isn't available

Contract:
- Inputs:
  - user_input: dict (e.g., {"clothing_type": str, "material": [str]|str, "color": [str]|str, "pattern": str, "style": str})
  - fabric_list: list[dict] with keys: fabric_id, name, material, color, pattern, price, stock, supplier_id
- Output: list[str] of fabric_id ranked by relevance
"""
from typing import Dict, List, Any

try:
    # scikit-learn is optional; we use it when present
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.metrics.pairwise import cosine_similarity
    _SKLEARN_AVAILABLE = True
except Exception:  # pragma: no cover - keep runtime resilient
    _SKLEARN_AVAILABLE = False


def _normalize(value: Any) -> str:
    return str(value).strip().lower() if value is not None else ""


def _tokenize(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [_normalize(v) for v in value if v is not None]
    # support comma-separated entries; keep multi-word tokens intact
    txt = _normalize(value)
    if not txt:
        return []
    parts = [p.strip() for p in txt.split(',') if p.strip()]
    return parts if parts else [txt]


def _compose_profile(entry: Dict[str, Any]) -> str:
    """Create a textual profile for TF-IDF from fabric or user input.

    We repeat salient attributes to implicitly weight them higher in TF-IDF space.
    """
    name = _normalize(entry.get("name"))
    material_tokens = _tokenize(entry.get("material"))
    color_tokens = _tokenize(entry.get("color"))
    pattern = _normalize(entry.get("pattern"))
    style = _normalize(entry.get("style"))

    # Implicit weights via repetition (material > color > pattern > name > style)
    parts: List[str] = []
    if name:
        parts.extend([name])
    if material_tokens:
        parts.extend(material_tokens * 3)
    if color_tokens:
        parts.extend(color_tokens * 2)
    if pattern:
        parts.extend([pattern] * 2)
    if style:
        parts.append(style)
    return " ".join(parts).strip()


def _availability_boost(stock_value: Any) -> float:
    try:
        return 0.25 if int(stock_value or 0) > 0 else 0.0
    except Exception:
        return 0.0


def _rule_based_rank(user_input: Dict[str, Any], fabric_list: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Original lightweight attribute-based scorer; returns sorted list of dicts."""
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
        s += _availability_boost(f.get("stock", 0))
        return s

    ranked = sorted(fabric_list, key=score, reverse=True)
    # Filter out items with zero score if user specified constraints
    has_constraints = bool(desired_materials or desired_colors or desired_pattern)
    if has_constraints:
        ranked = [f for f in ranked if score(f) > 0]
    return ranked


def _ml_rank(user_input: Dict[str, Any], fabric_list: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Content-based ranking using TF-IDF and cosine similarity.

    Returns fabrics sorted by combined score: 0.9*cosine + 0.1*availability.
    """
    # Build corpus from fabrics
    corpus = [_compose_profile(f) for f in fabric_list]
    # Compose the query document from user input
    query_doc = _compose_profile(user_input)

    # Edge case: if everything is empty, just return as-is
    if not any(corpus) and not query_doc:
        return fabric_list

    # Vectorize with moderate n-grams to capture phrases like "navy blue"
    vectorizer = TfidfVectorizer(lowercase=True, analyzer="word", ngram_range=(1, 2), min_df=1)
    try:
        item_matrix = vectorizer.fit_transform(corpus)
        query_vec = vectorizer.transform([query_doc])
    except Exception:
        # If vectorization fails for any reason, fall back to rule-based
        return _rule_based_rank(user_input, fabric_list)

    # Cosine similarity scores (shape: [n_items])
    sims = cosine_similarity(item_matrix, query_vec).ravel()

    # Small availability boost to keep parity with previous behavior
    boosts = [_availability_boost(f.get("stock", 0)) for f in fabric_list]

    # Weighted final score (per-item availability boost)
    np = __import__('numpy')
    boosts_arr = np.array(boosts, dtype=float)
    final_scores = (0.9 * sims) + (0.1 * boosts_arr)

    # Sort fabrics by score
    idx_sorted = sorted(range(len(fabric_list)), key=lambda i: final_scores[i], reverse=True)
    ranked = [fabric_list[i] for i in idx_sorted]

    # If user provided constraints, filter out zero-similarity items (tolerance)
    desired_materials = set(_tokenize(user_input.get("material")))
    desired_colors = set(_tokenize(user_input.get("color")))
    desired_pattern = _normalize(user_input.get("pattern"))
    has_constraints = bool(desired_materials or desired_colors or desired_pattern)
    if has_constraints:
        ranked = [f for i, f in enumerate(ranked) if sims[idx_sorted[i]] > 1e-12 or _availability_boost(f.get("stock", 0)) > 0]

    return ranked


def recommend_fabrics(user_input: Dict[str, Any], fabric_list: List[Dict[str, Any]], top_n: int = 12) -> List[str]:
    """Recommend top-N fabrics using ML when available, else fallback.

    Returns a list of fabric_id as strings.
    """
    ranked: List[Dict[str, Any]]
    if _SKLEARN_AVAILABLE:
        try:
            ranked = _ml_rank(user_input, fabric_list)
        except Exception:
            ranked = _rule_based_rank(user_input, fabric_list)
    else:
        ranked = _rule_based_rank(user_input, fabric_list)

    top = ranked[:top_n]
    return [str(f.get("fabric_id")) for f in top]


def recommend_fabrics_from_db(
    user_input: Dict[str, Any],
    top_n: int = 12,
    return_objects: bool = False,
    queryset: Any = None,
) -> List[Any]:
    """Convenience wrapper that pulls fabrics from the database and applies AI ranking.

    - If Django/DB is not available, raises ImportError with guidance.
    - Returns a list of fabric_ids (strings) by default; set return_objects=True to get Fabric instances
      ordered by relevance.
    - You can pass a pre-filtered queryset to limit candidate fabrics (e.g., in-stock only).
    """
    try:
        from marketplace.models import Fabric  # lazy import to avoid Django app init at module import
    except Exception as e:
        raise ImportError("Django models are not available; ensure this runs within a Django context.") from e

    if queryset is None:
        queryset = Fabric.objects.all()

    # Prepare the dataset for the core recommender (decoupled from ORM)
    fabric_dataset = list(
        queryset.values(
            "fabric_id",
            "name",
            "material",
            "color",
            "pattern",
            "price",
            "stock",
            "supplier_id",
        )
    )

    top_ids = recommend_fabrics(user_input, fabric_dataset, top_n=top_n)
    if not return_objects:
        return top_ids

    # Fetch and order Fabric instances according to AI ranking
    objs = {f.fabric_id: f for f in Fabric.objects.filter(fabric_id__in=top_ids)}
    ordered = [objs[fid] for fid in top_ids if fid in objs]
    return ordered
