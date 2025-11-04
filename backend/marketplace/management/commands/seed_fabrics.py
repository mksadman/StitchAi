import random
import string
from typing import List

from django.core.management.base import BaseCommand, CommandError
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


def image_url_for(fabric_id: str) -> str:
    # Deterministic placeholder image URL; not stored (model has no image field)
    seed = fabric_id.replace("-", "")
    return f"https://picsum.photos/seed/{seed}/600/800"


class Command(BaseCommand):
    help = "Seed the database with random Fabric entries (30–50 by default)."

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
        count = requested if requested > 0 else random.randint(30, 50)

        created = 0
        attempts = 0
        max_attempts = count * 5  # guard against infinite loops on unique IDs

        self.stdout.write(self.style.NOTICE(f"Seeding {count} fabric entries{' (dry-run)' if dry_run else ''}..."))

        while created < count and attempts < max_attempts:
            attempts += 1
            material = random.choice(MATERIALS)
            color = random.choice(COLORS)
            pattern = random.choice(PATTERNS)
            price = random_price()
            stock = random_stock()
            supplier_id = random.choice(SUPPLIERS)
            fid = random_id()
            name = random_name(material, pattern, color)
            img_url = image_url_for(fid)

            # Print a compact line preview, including image URL (not stored)
            self.stdout.write(
                f"[{created + 1:02d}/{count}] {fid} | {name} | mat={material}, color={color}, pattern={pattern}, "
                f"price={price}, stock={stock}, supplier={supplier_id} | image={img_url}"
            )

            if not dry_run:
                # Ensure business ID uniqueness; if collision happens, retry
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
                )

            created += 1

        if created < count:
            self.stdout.write(self.style.WARNING(
                f"Stopped after {created} records (target {count}); attempts limit reached."
            ))
        else:
            self.stdout.write(self.style.SUCCESS(f"Created {created} fabric entries."))
