from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .ai.fabric_recommender import recommend_fabrics
from .models import Fabric
from .serializers import FabricSerializer


class RecommendFabricView(APIView):
    """
    POST /recommend-fabrics/
    - Accepts user requirements JSON
    - Passes requirements + fabric dataset to AI module
    - Receives list of fabric_ids from AI
    - Returns serialized fabric records matching those IDs
    """

    def post(self, request):
        # Basic payload validation: accept any subset; AI decides relevancy.
        if not isinstance(request.data, dict):
            return Response({"detail": "Invalid payload: expected JSON object."}, status=status.HTTP_400_BAD_REQUEST)

        user_input = request.data

        # Gather dataset for AI (dicts to keep module decoupled from ORM)
        fabric_dataset = list(
            Fabric.objects.all().values(
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

        # Delegate selection to AI
        try:
            top_fabric_ids = recommend_fabrics(user_input, fabric_dataset)
        except Exception as e:
            return Response({"detail": f"AI recommendation failed: {e}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        if not top_fabric_ids:
            return Response([], status=status.HTTP_200_OK)

        # Query details by business identifier fabric_id
        queryset = Fabric.objects.filter(fabric_id__in=top_fabric_ids)

        # Preserve AI ranking order
        fabrics_by_id = {f.fabric_id: f for f in queryset}
        ordered_records = [fabrics_by_id[fid] for fid in top_fabric_ids if fid in fabrics_by_id]

        serializer = FabricSerializer(ordered_records, many=True, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)
