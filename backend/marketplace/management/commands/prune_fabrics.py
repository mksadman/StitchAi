import os
from pathlib import Path
from typing import List

from django.core.management.base import BaseCommand
from django.conf import settings
from marketplace.models import Fabric


def list_cloth_images() -> List[str]:
    """List image filenames present in MEDIA_ROOT (clothimages)."""
    media_root: Path = Path(getattr(settings, 'MEDIA_ROOT', Path.cwd()))
    if not media_root.exists():
        return []
    exts = {'.jpg', '.jpeg', '.png'}
    return [f for f in os.listdir(media_root) if Path(f).suffix.lower() in exts]


def normalize_media_prefix() -> str:
    prefix = getattr(settings, 'MEDIA_URL', '/media/') or '/media/'
    if not prefix.startswith('/'):
        prefix = '/' + prefix
    if not prefix.endswith('/'):
        prefix = prefix + '/'
    return prefix


class Command(BaseCommand):
    help = "Delete all Fabric rows not backed by images in backend/clothimages (keep only those 8)."

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without modifying the database.',
        )

    def handle(self, *args, **options):
        dry = bool(options.get('dry_run', False))

        prefix = normalize_media_prefix()
        files = list_cloth_images()
        keep_urls = {f"{prefix}{fname}" for fname in files}

        total = Fabric.objects.count()
        keep_count = Fabric.objects.filter(image_url__in=list(keep_urls)).count()
        to_delete_qs = Fabric.objects.exclude(image_url__in=list(keep_urls))
        delete_count = to_delete_qs.count()

        self.stdout.write(self.style.NOTICE(
            f"Total fabrics: {total} | Keep: {keep_count} | Delete: {delete_count}"
        ))
        if dry:
            self.stdout.write(self.style.WARNING("Dry-run enabled: no changes made."))
            return

        # Perform deletion
        deleted = to_delete_qs.delete()
        # deleted is a tuple: (num_deleted, details_dict)
        self.stdout.write(self.style.SUCCESS(
            f"Deleted {deleted[0]} records not in clothimages. Kept {keep_count}."
        ))