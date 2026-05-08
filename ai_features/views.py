from django.http import JsonResponse
from .services import AIAgentService

def test_icebreaker(request):
    agent = AIAgentService()
    # Date de test (ulterior le vom lua din baza de date/Profile)
    result = agent.generate_icebreaker(
        user_interests="muzică rock, gaming, cafea",
        match_interests="chitară, concerte, jocuri video",
        location="București"
    )
    return JsonResponse({"icebreaker_suggestion": result})
def test_matchmaker(request):
    agent = AIAgentService()
    
    # Datele tale de test
    me = "Mă numesc Maria. Interese: rock, festivaluri, cafea. Bio: Caut pe cineva pentru concerte."
    
    # Lista de potențiali prieteni
    others = [
        "Andrei - Interese: chitara, rock, bere. Bio: Iubesc muzica live și formez o trupă.",
        "Ion - Interese: fotbal, masini, fifa. Bio: Imi place sportul și weekendurile liniștite.",
        "Elena - Interese: cafea de specialitate, arta, teatru. Bio: Pasionata de frumos și plimbări prin oraș."
    ]
    
    result = agent.generate_smart_match(current_user_data=me, other_profiles_data=others)
    
    return JsonResponse({"matchmaker_result": result})