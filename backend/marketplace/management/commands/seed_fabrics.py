import random
import string
import os
from pathlib import Path
from typing import List

from django.core.management.base import BaseCommand
from django.conf import settings
from marketplace.models import Fabric


MATERIALS: List[str] = [
    "cotton", "linen", "silk", "wool", "polyester", "rayon", "denim", "chiffon", "satin",
]

COLORS: List[str] = [
    "white", "black", "navy blue", "royal blue", "sky blue", "red", "maroon", "green", "olive",
    "yellow", "mustard", "orange", "purple", "violet", "pink", "magenta", "beige", "brown",
    "gray", "charcoal", "teal",
]

PATTERNS: List[str] = [
    "plain", "striped", "checked", "plaid", "floral", "polka dot", "herringbone", "houndstooth",
    "paisley", "geometric",
]

SUPPLIERS: List[str] = [
    "SUP-A", "SUP-B", "SUP-C", "SUP-D", "SUP-E",
]


def random_id(prefix: str = "FAB", size: int = 8) -> str:
    pool = string.ascii_uppercase + string.digits
    return f"{prefix}-" + "".join(random.choices(pool, k=size))


def random_name(material: str, pattern: str, color: str) -> str:
    adjectives = [
        "Classic", "Premium", "Soft", "Luxe", "Elegant", "Everyday", "Heritage", "Urban",
        "Essential", "Comfort", "Signature", "Original",
    ]
    base = f"{random.choice(adjectives)} {material.title()}"
    # Include pattern if not plain
    if pattern != "plain":
        base += f" {pattern.title()}"
    # Include one color word (first token)
    base += f" {color.split()[0].title()}"
    return base


def random_price() -> float:
    # Price between 4.99 and 49.99
    return round(random.uniform(4.99, 49.99), 2)


def random_stock() -> int:
    # Stock between 0 and 250
    return int(random.triangular(0, 250, 50))

def list_cloth_images() -> List[str]:
    """List available cloth image filenames in MEDIA_ROOT (clothimages)."""
    media_root: Path = Path(getattr(settings, 'MEDIA_ROOT', Path.cwd()))
    exts = {'.jpg', '.jpeg', '.png'}
    if not media_root.exists():
        return []
    return [f for f in os.listdir(media_root) if Path(f).suffix.lower() in exts]

def _normalize_color_token(tok: str) -> str:
    t = tok.lower()
    mapping = {
        'navyblue': 'navy blue',
        'royalblue': 'royal blue',
        'skyblue': 'sky blue',
        'darkgray': 'gray',
        'grey': 'gray',
    }
    return mapping.get(t, t)

def parse_metadata_from_filename(filename: str) -> dict:
    name_no_ext = Path(filename).stem
    tokens = [t.strip().lower() for t in name_no_ext.replace('-', '_').split('_') if t.strip()]
    # Material
    material = next((t for t in tokens if t in MATERIALS), None)
    # Color (support compact tokens like navyblue)
    color_candidates = {_normalize_color_token(t) for t in tokens}
    color = next((c for c in color_candidates if c in COLORS), None)
    # Pattern keywords
    patterns = ['plain', 'striped', 'checked', 'plaid', 'floral', 'polka dot', 'herringbone', 'houndstooth', 'paisley', 'geometric']
    pattern = next((p for p in patterns if p in tokens), None) or 'plain'
    # Clothing type (for naming only)
    types = ['shirt', 'tshirt', 'pant', 'dress', 'sweater', 'jeans']
    ctype = next((t for t in tokens if t in types), None)
    # Defaults if missing
    if not material:
        material = random.choice(MATERIALS)
    if not color:
        color = random.choice(COLORS)
    # Construct display name
    adjectives = [
        "Classic", "Premium", "Soft", "Luxe", "Elegant", "Everyday", "Heritage", "Urban",
        "Essential", "Comfort", "Signature", "Original",
    ]
    base = f"{random.choice(adjectives)} {material.title()}"
    if pattern and pattern != 'plain':
        base += f" {pattern.title()}"
    if ctype:
        base += f" {ctype.title()}"
    base += f" {color.split()[0].title()}"
    return {
        'material': material,
        'color': color,
        'pattern': pattern,
        'name': base,
    }


class Command(BaseCommand):
    help = "Seed the database with Fabric entries based on backend/clothimages filenames."

    def add_arguments(self, parser):
        parser.add_argument(
            "--count",
            type=int,
            default=0,
            help="Number of rows to create. If 0, a random value in [30, 50] is used.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Print what would be created without writing to the database.",
        )

    def handle(self, *args, **options):
        requested = options.get("count") or 0
        dry_run = options.get("dry_run", False)
        media_root: Path = Path(getattr(settings, 'MEDIA_ROOT', Path.cwd()))
        images = list_cloth_images()
        if requested > 0:
            images = images[:requested]

        created = 0
        self.stdout.write(self.style.NOTICE(
            f"Seeding {len(images)} fabric entries from {media_root}{' (dry-run)' if dry_run else ''}..."
        ))

        for idx, fname in enumerate(images, start=1):
            meta = parse_metadata_from_filename(fname)
            material = meta['material']
            color = meta['color']
            pattern = meta['pattern']
            name = meta['name']
            price = random_price()
            stock = random_stock()
            supplier_id = random.choice(SUPPLIERS)
            fid = random_id()
            img_url = f"{settings.MEDIA_URL}{fname}"

            self.stdout.write(
                f"[{idx:02d}/{len(images)}] {fid} | {name} | mat={material}, color={color}, pattern={pattern}, "
                f"price={price}, stock={stock}, supplier={supplier_id} | image={img_url}"
            )

            if not dry_run:
                if Fabric.objects.filter(fabric_id=fid).exists():
                    continue
                Fabric.objects.create(
                    fabric_id=fid,
                    name=name,
                    material=material,
                    color=color,
                    pattern=pattern,
                    price=price,
                    stock=stock,
                    supplier_id=supplier_id,
                    image_url=img_url,
                )

            created += 1

        self.stdout.write(self.style.SUCCESS(f"Created {created} fabric entries."))
