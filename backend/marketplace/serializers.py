from rest_framework import serializers
from .models import Fabric


class FabricSerializer(serializers.ModelSerializer):
    class Meta:
        model = Fabric
        fields = (
            'fabric_id',
            'name',
            'material',
            'color',
            'pattern',
            'price',
            'stock',
            'supplier_id',
        )
