import os
from langchain_groq import ChatGroq
from langchain_core.prompts import PromptTemplate
from dotenv import load_dotenv

load_dotenv()

class AIAgentService:
    def __init__(self):
        # Inițializăm modelul Llama 3 via Groq
        self.llm = ChatGroq(
            temperature=0.7, 
            groq_api_key=os.getenv("GROQ_API_KEY"), 
            model_name="llama-3.1-8b-instant"
        )

    def generate_icebreaker(self, user_interests, match_interests, location="București"):
        template = """
        Ești un asistent inteligent pentru o aplicație de dating numită BuddyUp.
        Utilizatorul A are următoarele interese: {user_interests}.
        Utilizatorul B are următoarele interese: {match_interests}.
        Amândoi sunt în locația: {location}.

        Sugerează 3 idei de conversație (icebreakers) și o locație/activitate specifică în orașul lor unde ar putea ieși, bazându-te pe interesele lor comune.
        Răspunde prietenos, în limba română.
        """
        
        prompt = PromptTemplate(
            input_variables=["user_interests", "match_interests", "location"],
            template=template,
        )
        
        # Combinăm prompt-ul cu datele și apelăm AI-ul
        chain = prompt | self.llm
        response = chain.invoke({
            "user_interests": user_interests,
            "match_interests": match_interests,
            "location": location
        })
        
        return response.content

    # ADAUGĂ ACEASTĂ FUNCȚIE NOUĂ:
    def generate_smart_match(self, current_user_data, other_profiles_data):
        template = """
        Ești un sistem inteligent de matchmaking pentru aplicația BuddyUp.
        Utilizatorul curent are următorul profil: {current_user}
        Ai la dispoziție următoarea listă de potențiale potriviri: {profiles_list}

        Analizează interesele și bio-ul fiecăruia. Alege cele mai bune 2 potriviri pentru utilizatorul curent, dincolo de filtrele de bază.
        Oferă rezultatul tău într-un mod prietenos, spunând numele persoanei, un procentaj estimat de compatibilitate și o frază scurtă despre motivul potrivirii.
        Răspunde în limba română.
        """
        
        prompt = PromptTemplate(
            input_variables=["current_user", "profiles_list"],
            template=template,
        )
        
        chain = prompt | self.llm
        response = chain.invoke({
            "current_user": current_user_data,
            "profiles_list": other_profiles_data
        })
        
        return response.content