# Politica de confidențialitate — CarPlanner (Auto Calendar)

_Ultima actualizare: 28 iulie 2026_

## Română

**CarPlanner** este o aplicație offline. Nu are server/backend propriu și nu
trimite automat date către niciun serviciu extern.

### Ce date sunt stocate și unde

Toate datele pe care le introduci (mașini, kilometraj, revizii, documente
RCA/CASCO/Rovinietă/ITP, remindere, poze și PDF-uri atașate) sunt salvate
**exclusiv local, pe telefonul tău**, într-o bază de date SQLite din
storage-ul propriu al aplicației. Nimic din acestea nu este trimis către
un server, nu este sincronizat în cloud și nu este accesibil altor
aplicații.

Dezinstalarea aplicației șterge definitiv toate aceste date.

### Jurnal de erori (local, nu automat)

Aplicația păstrează un jurnal text local cu ultimele erori tehnice
întâmpinate (ex. o excepție neașteptată), strict pe dispozitiv, ca să te
poată ajuta pe tine sau pe dezvoltator să depaneze o problemă. Acest jurnal
**nu este trimis nicăieri automat** — poate fi trimis doar dacă tu alegi
manual, din ecranul Setări → Feedback, să-l atașezi la un email.

Aplicația **nu folosește niciun serviciu de analytics sau crash reporting
extern** (ex. Firebase Crashlytics, Google Analytics) — decizie
deliberată, ca să nu părăsească nicio informație dispozitivul fără
acțiunea ta explicită.

### Permisiuni folosite și de ce

- **Cameră/Galerie** — pentru fotografierea/scanarea talonului auto și a
  polițelor RCA/CASCO (OCR pe dispozitiv, cu `google_mlkit_text_recognition`
  — procesare 100% locală, nimic nu e trimis către Google sau altcineva).
- **Calendar (citire/scriere)** — doar dacă alegi explicit „Salvează în
  calendar" pentru un document sau o revizie; adaugă un eveniment în
  calendarul telefonului tău.
- **Notificări** — pentru remindere locale (expirare documente, revizii
  programate, componente de mentenanță).
- **Stocare/fișiere** — pentru atașarea unui PDF (poliță RCA/CASCO) la un
  document.

### Servicii terțe folosite doar ca „deschide pagina" (fără date trimise de aplicație)

Butonul „Verifică pe site-ul oficial" din ecranul unui document RCA/ITP/
Rovinietă deschide, în browser-ul telefonului, pagina oficială RAR/AIDA/
CNAIR — aplicația doar copiază în clipboard un identificator (număr de
înmatriculare sau VIN) ca să-l poți lipi tu manual acolo. Aplicația nu
transmite nimic direct acestor site-uri.

### Contact

Pentru întrebări despre confidențialitate: **crdo0809@gmail.com**

---

## English

**CarPlanner** is an offline app. It has no server/backend of its own and
does not automatically send data to any external service.

### What data is stored, and where

Everything you enter (vehicles, mileage, service history, RCA/CASCO/Road
Toll/Technical Inspection documents, reminders, attached photos and PDFs)
is saved **exclusively on your phone**, in a local SQLite database inside
the app's own storage. None of it is sent to a server, synced to any
cloud, or accessible to other apps.

Uninstalling the app permanently deletes all of this data.

### Error log (local only, not sent automatically)

The app keeps a local text log of the last technical errors it
encountered (e.g. an unexpected exception), strictly on-device, to help
you or the developer debug an issue. This log **is never sent
anywhere automatically** — it can only be sent if you manually choose to,
from Settings → Feedback, by attaching it to an email.

The app **does not use any external analytics or crash-reporting
service** (e.g. Firebase Crashlytics, Google Analytics) — a deliberate
choice so that no information leaves the device without your explicit
action.

### Permissions used and why

- **Camera/Gallery** — to photograph/scan the vehicle registration card
  and RCA/CASCO policies (on-device OCR via
  `google_mlkit_text_recognition` — 100% local processing, nothing is
  sent to Google or anyone else).
- **Calendar (read/write)** — only when you explicitly tap "Save to
  calendar" for a document or service record; adds an event to your
  phone's calendar.
- **Notifications** — for local reminders (document expiry, scheduled
  service, maintenance components).
- **Storage/files** — to attach a PDF (RCA/CASCO policy) to a document.

### Third-party services used only to "open the page" (no data sent by the app)

The "Check on the official site" button on an RCA/Technical
Inspection/Road Toll document opens the official RAR/AIDA/CNAIR page in
the phone's browser — the app only copies an identifier (plate number or
VIN) to the clipboard so you can paste it there yourself. The app does
not transmit anything directly to these sites.

### Contact

For privacy questions: **crdo0809@gmail.com**
