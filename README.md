# BuddyUp
BuddyUp este o platformă mobilă concepută pentru a facilita
conexiunile umane autentice în mediul offline. Spre deosebire de aplicațiile de dating,
BuddyUp elimină presiunea romantică, concentrându-se exclusiv pe formarea de prietenii și
grupuri de activități. 

BuddyUp este o aplicatie full-stack de socializare dezvoltata folosind framework-urile Flutter si Django. Sistemul este conceput pentru a facilita conectarea utilizatorilor pe baza intereselor comune si a proximitatii, utilizand o arhitectura decuplata si un API REST pentru comunicarea datelor.

---

## Caracteristici Principale

### Frontend (Flutter)
* **Sistem de Swipe (Card Swiper):** Interfata dinamica pentru navigarea prin profilurile utilizatorilor, implementata cu animatii pentru actiunile de tip aprobare sau respingere.
* **Notificari de Match in Timp Real:** Sistem de feedback vizual prin SnackBars care confirma producerea unei potriviri reciproce in momentul interactiunii.
* **Managementul Profilului:** Functionalitati pentru editarea datelor personale, inclusiv varsta, biografie si interese, alaturi de gestionarea imaginilor de profil.
* **Director de Match-uri:** Sectiune dedicata pentru vizualizarea listei utilizatorilor cu care s-a stabilit o conexiune reciproca.

### Backend (Django REST Framework)
* **Algoritm de Matching:** Logica server-side care monitorizeaza interactiunile si valideaza reciprocitatea inainte de a instantia un obiect de tip Match in baza de date.
* **Sistem de Filtrare si Discovery:** Algoritm care exclude profilul propriu si gestioneaza utilizatorii deja vizualizati pentru a optimiza fluxul de date catre client.
* **Normalizarea Datelor:** Procesarea textului prin eliminarea diacriticelor si conversia la minuscule pentru a asigura precizia interogarilor.
* **Servirea Continutului Media:** Configurarea serverului pentru gestionarea si livrarea imaginilor de profil prin URL-uri dinamice.

---

## Stack Tehnologic

| Strat | Tehnologie |
| :--- | :--- |
| **Frontend** | Flutter (Dart) |
| **Backend** | Django 5.x & Django REST Framework |
| **Baza de date** | SQLite |
| **Utilitare** | Geopy (Sistem GPS), Unicodedata (Procesare text) |
| **Arhitectura** | REST API (JSON peste HTTP) |

---

## Arhitectura Sistemului

Proiectul utilizeaza un model de arhitectura Client-Server:
1. **Clientul (Flutter)** initiaza cereri HTTP (GET pentru preluarea profilurilor, POST pentru inregistrarea actiunilor de swipe).
2. **Serverul (Django)** receptioneaza cererile, executa logica de business si interogheaza baza de date.
3. **Sistemul de Raspuns:** Serverul returneaza date in format JSON, permitand clientului sa actualizeze interfata fara a reincarca intreaga aplicatie.

---

## Instalare si Configurare

### Backend (Django)
1. Accesati directorul destinat backend-ului.
2. Initializati un mediu virtual: `python -m venv venv`.
3. Instalati pachetele necesare: 
   ```bash
   pip install django djangorestframework django-cors-headers geopy
