from django.db import models


class Fabric(models.Model):
	"""
	Represents a fabric item available in the marketplace.
	Note: fabric_id is a business identifier distinct from the DB primary key (id).
	"""
	fabric_id = models.CharField(max_length=64, unique=True, db_index=True)
	name = models.CharField(max_length=255)
	material = models.CharField(max_length=128)
	color = models.CharField(max_length=128)
	pattern = models.CharField(max_length=128, blank=True)
	price = models.DecimalField(max_digits=10, decimal_places=2)
	stock = models.IntegerField(default=0)
	supplier_id = models.CharField(max_length=64)

	class Meta:
		ordering = ["name"]

	def __str__(self) -> str:  # pragma: no cover
		return f"{self.name} ({self.fabric_id})"
