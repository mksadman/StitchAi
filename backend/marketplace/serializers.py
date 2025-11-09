from rest_framework import serializers
from .models import Fabric


class FabricSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

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
            'image_url',
        )

    def get_image_url(self, obj) -> str:
        url = (obj.image_url or '').strip()
        if not url:
            return ''
        if url.startswith('http://') or url.startswith('https://'):
            return url
        if not url.startswith('/'):
            url = '/' + url.lstrip('/')
        request = self.context.get('request') if isinstance(self.context, dict) else None
        if request is not None:
            try:
                return request.build_absolute_uri(url)
            except Exception:
                pass
        return url
