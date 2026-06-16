# BuddyUp! - Social Matching Application

BuddyUp este o aplicație mobilă de tip social matching în plină dezvoltare, concepută pentru a facilita conexiuni autentice între utilizatori prin intermediul unui sistem de profiluri detaliate, swipe-uri și match-uri inteligente bazate pe interese comune.

Proiectul este dezvoltat folosind tehnologiile **Flutter** (pentru frontend-ul mobil) și **Django REST Framework** (pentru backend-ul robust).

## Prezentare Vizuală (Screenshots - În dezvoltare)

| Register | Login | Home (Swipe) |
| --- | --- | --- |
|  |  |  |

| Profile | Edit Profile | Chat |
| --- | --- | --- |
|  |  |  |

---

## Funcționalități Implementate & Logica de Business

Această secțiune detaliază motorul aplicației, explicând cum interacționează utilizatorii și cum sunt gestionate datele.

### 1. Sistem de Înregistrare și Autentificare (Securitate)

* **Creare Cont:** Permite utilizatorilor noi să își creeze un cont folosind un username unic și o parolă.
* **Securitate la Nivel de Backend:** Parolele nu sunt salvate în clar; Django le securizează automat folosind sistemul său intern de hashing (PBKDF2 cu SHA256).
* **Validare REST:** Backend-ul verifică automat unicitatea username-ului și validează datele. Schimbul de date se realizează exclusiv prin endpoint-uri REST în format JSON, cu gestionarea erorilor.

### 2. Managementul Profilului și Localizare (GPS)

* **Profil Detaliat:** Utilizatorii își pot personaliza profilul cu biografie, vârstă și interese (selectate dintr-o listă predefinită).
* **Management Media:** Încărcarea unei poze de profil și a unei galerii de imagini, folosind pachetul `image_picker` pe telefon.
* **Integrare GPS:** Aplicația preia coordonatele geografice (latitudine și longitudine) ale utilizatorului pentru a permite viitoare funcționalități de proximitate (ex: afișarea distanței).

### 3. Motorul de Social Matching (Swipe & Match)

Acesta este nucleul aplicației. Logica a fost implementată pentru a genera conexiuni relevante.

#### A. Mecanica Swipe (LIKE/PASS)

Backend-ul oferă un endpoint REST (/swipes/api/inregistreaza-swipe/) care primește trei parametri:

1. Utilizatorul care oferă swipe-ul.
2. Utilizatorul care primește swipe-ul.
3. Acțiunea (LIKE - dreapta sau PASS - stânga).

Dacă utilizatorul a oferit deja un swipe aceleiași persoane, acțiunea anterioară este ștearsă și înlocuită cu cea nouă.

#### B. Generarea Automată a Match-urilor

Aplicația implementează logica de „LIKE reciproc”. Atunci când un utilizator oferă un LIKE (acțiunea 'RIGHT'), backend-ul verifică instantaneu dacă există un LIKE anterior din partea celuilalt utilizator.

* Dacă ambele LIKE-uri există, un **Match** este creat automat între cei doi utilizatori.

#### C. Descoperirea Profilurilor prin Interese Comune

Un endpoint major (`/swipes/api/get-utilizatori-filtrati/`) a fost implementat pentru a popula ecranul de Swipe. Acesta folosește un algoritm de filtrare complex:

* **Excludere Sine:** Utilizatorul curent nu se va vedea niciodată pe sine în lista de swipe.
* **Excludere Match-uri Existente:** Utilizatorii cu care ești deja într-un match nu vor apărea.
* **Filtrare după Interese Comune:** Aplicația returnează doar profilurile utilizatorilor care **împărtășesc cel puțin un interes** cu utilizatorul curent. Acest lucru asigură că swipe-urile sunt oferite pe baza unei posibile compatibilități, nu doar vizual.

---

## Specificații Tehnice & Arhitectură

### Frontend (Flutter)

Aplicația mobilă este construită pe o arhitectură modulară, gestionând starea profilului și imaginile dinamic.

* **UI/UX:** Widget-uri Flutter native și pachete comunitare precum `flutter_card_swiper` pentru mecanica swipe.
* **Networking:** Pachetul `http` este utilizat pentru cereri REST și cereri multipart (necesare pentru încărcarea pozelor de profil/galerie).
* **Pachete Cheie:** `http`, `image_picker`, `flutter_card_swiper`, `geolocator`.

### Backend (Django & Django REST Framework)

Backend-ul este structurat în aplicații Django separate (`swipes`, `profiles`, `matches`, `buddyup`), oferind o API REST securizată.

* **Modele de Date Principală:**
* `Profile`: Extinde modelul `User` pentru a stoca biografia, vârsta, interesele, coordonatele GPS și media.
* `Swipe`: Înregistrează fiecare interacțiune (Swiper, Swiped_User, Tip: LIKE/PASS).
* `Match`: Înregistrează conexiunile (User1, User2) create din LIKE-uri reciproce, cu utilizatorii sortați automat după ID pentru a evita duplicatele.


* **API Tehnici:** Utilizarea `MultiPartParser` și `FormParser` pentru gestionarea eficientă a încărcărilor media. Imaginile sunt salvate local pe server și accesate prin URL-uri absolute.

---

## Ghid de Dezvoltare și Testare Locală

Acest proiect include o configurare specială pentru a facilita testarea pe emulatorul Android, care vede serverul local la o adresă IP diferită.

### Configurarea Android Emulator

Când se rulează backend-ul pe `127.0.0.1:8000` (localhost), emulatorul Android nu îl poate accesa direct.

* **Rulare Backend:** Serverul Django trebuie pornit pe `0.0.0.0` pentru a accepta conexiuni externe:
```bash
python manage.py runserver 0.0.0.0:8000

```


* **Android IP Bridge:** Flutter a fost configurat pentru a converti automat adresa IP locală a imaginilor. În cod, `127.0.0.1` este înlocuit cu `10.0.2.2`, care este adresa specială folosită de emulatorul Android pentru a accesa localhost-ul mașinii gazdă.

### Cerințe Instalare

(Se vor adăuga instrucțiunile de instalare pentru Flutter, Django și baza de date, odată ce proiectul este gata pentru deployment local).

---

## Echipa de Dezvoltare

* Vișan Laura-Mihaela
* Pîrvulescu Maria-Eliza
* Țigănilă Ștefania
