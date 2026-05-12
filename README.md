# BuddyUp! - Social Matching Application

BuddyUp este o aplicație mobilă de tip social matching, dezvoltată folosind tehnologiile Flutter și Django REST Framework. Scopul aplicației este de a facilita interacțiunea dintre utilizatori prin intermediul unui sistem de profiluri, swipe-uri și match-uri.

## Prezentare Vizuală (Screenshots)

| Register | Login | Home (Swipe) |
| :---: | :---: | :---: |
| ![Register](screenshots/register.jpg) | ![Login](screenshots/login.jpg) | ![Home](screenshots/home.jpg) |

| Profile | Edit Profile | Chat |
| :---: | :---: | :---: |
| ![Profile](screenshots/profile.jpg) | ![Edit](screenshots/edit_profile.jpg) | ![Chat](screenshots/chat.jpg) |

---

## Funcționalități Implementate

### Sistem de Înregistrare și Autentificare
* **Creare Cont:** Permite utilizatorilor să își creeze conturi noi folosind un username, email și parolă.
* **Securitate:** Parolele sunt securizate automat folosind sistemul de hashing oferit de Django.
* **Validare:** Backend-ul verifică unicitatea username-ului și validează datele introduse.
* **Comunicare:** Schimbul de date se realizează prin endpoint-uri REST (/users/register/ și /users/login/) în format JSON.

### Sistemul de Profil
* **Personalizare:** Utilizatorii pot adăuga biografia (bio), interesele și vârsta.
* **Management Media:** Încărcarea pozei de profil și a unei galerii de imagini folosind pachetul image_picker.
* **Localizare:** Stocarea coordonatelor geografice (latitudine și longitudine) pentru funcții de proximitate.

### Interacțiune și Social Matching
* **Sistem Swipe:** Permite utilizatorilor să ofere Like sau Pass altor profiluri.
* **Generare Match:** În cazul în care doi utilizatori își oferă reciproc Like, aplicația generează automat un match între aceştia.
* **Vizualizare:** Posibilitatea de a vedea profilurile detaliate ale altor utilizatori înainte de a decide.

---

## Specificații Tehnice

### Frontend (Flutter)
* **Interfață:** Construită dinamic folosind widget-uri precum GridView, CircleAvatar și Image.network.
* **Networking:** Utilizarea pachetului http pentru cereri de tip multipart (pentru imagini) și REST.
* **Compatibilitate:** Implementarea conversiilor de adrese IP pentru testarea pe emulatorul Android (10.0.2.2).

### Backend (Django)
* **REST API:** Dezvoltat cu Django REST Framework, utilizând MultiPartParser și FormParser pentru gestionarea fișierelor.
* **Stocare Media:** Imaginile sunt salvate pe server și accesate prin URL-uri absolute.

---
## Instrucțiuni de Instalare

### Configurare Backend
1. Instalați dependințele: `pip install -r requirements.txt`
2. Migrați baza de date: `python manage.py migrate`
3. Porniți serverul: `python manage.py runserver 0.0.0.0:8000`

### Configurare Frontend
1. Descărcați pachetele: `flutter pub get`
2. Rulați aplicația: `flutter run`

---

## Echipa de Dezvoltare
* Vișan Laura-Mihaela
* Pîrvulescu Maria-Eliza
* Țigănilă Ștefania
