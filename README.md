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
**Creare Cont:** Permite utilizatorilor să își creeze conturi noi folosind un username și o parolă.
**Securitate:** Parolele sunt securizate automat folosind sistemul de hashing oferit de Django.
**Validare:** Backend-ul verifică unicitatea username-ului și validează datele introduse.
**Comunicare:** Schimbul de date se realizează prin endpoint-uri REST în format JSON.

### Sistemul de Profil
**Personalizare:** Utilizatorii pot adăuga biografia, interesele și vârsta[cite: 221, 234].
**Management Media:** Încărcarea pozei de profil și a unei galerii de imagini folosind pachetul `image_picker`.
**Localizare:** Stocarea coordonatelor geografice (latitudine și longitudine) pentru funcții de proximitate.

### Interacțiune și Social Matching
**Sistem Swipe:** Permite utilizatorilor să ofere Like sau Pass altor profiluri.
**Generare Match:** În cazul în care doi utilizatori își oferă reciproc Like, aplicația generează automat un match.
**Vizualizare:** Posibilitatea de a vedea profilurile detaliate ale altor utilizatori înainte de a decid.

---

## Specificații Tehnice

### Frontend (Flutter)
**Interfață:** Construită dinamic folosind widget-uri precum `GridView`, `CircleAvatar` și `Image.network`.
**Networking:** Utilizarea pachetului `http` pentru cereri de tip multipart și REST.
**Compatibilitate:** Implementarea conversiilor de adrese IP (10.0.2.2) pentru testarea pe emulatorul Android.

### Backend (Django)
**REST API:** Dezvoltat cu Django REST Framework, utilizând `MultiPartParser` și `FormParser`.
**Stocare Media:** Imaginile sunt salvate pe server și accesate prin URL-uri absolute.

---

## Echipa de Dezvoltare
Vișan Laura-Mihaela 
Pîrvulescu Maria-Eliza 
Țigănilă Ștefania
