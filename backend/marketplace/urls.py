from django.urls import path
from .views import RecommendFabricView

urlpatterns = [
    path('recommend-fabrics/', RecommendFabricView.as_view(), name='recommend-fabrics'),
]
