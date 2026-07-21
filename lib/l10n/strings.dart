import '../services/region_service.dart';

/// Toate textele afișate în interfață, în română și engleză. Selectate
/// automat în funcție de țara aleasă în Setări — România păstrează
/// exact comportamentul original (RCA/CASCO/ITP/Rovinietă, în română),
/// orice altă țară primește denumiri generice, internaționale, în engleză.
class S {
  static bool get _ro => RegionService.instance.language == AppLanguage.ro;

  // ---------- General ----------
  static String get appName => 'CarPlanner';
  static String get requiredField => _ro ? 'Câmp obligatoriu' : 'Required field';
  static String get required => _ro ? 'Obligatoriu' : 'Required';
  static String get cancel => _ro ? 'Anulează' : 'Cancel';
  static String get delete => _ro ? 'Șterge' : 'Delete';
  static String get save => _ro ? 'Salvează' : 'Save';
  static String get saving => _ro ? 'Se salvează...' : 'Saving...';
  static String get camera => _ro ? 'Cameră' : 'Camera';
  static String get gallery => _ro ? 'Galerie' : 'Gallery';
  static String get notesOptional => _ro ? 'Observații — opțional' : 'Notes — optional';
  static String get notes => _ro ? 'Observații' : 'Notes';
  static String get none => _ro ? 'Niciuna' : 'None';
  static String get date => _ro ? 'Data' : 'Date';
  static String get car => _ro ? 'Mașină' : 'Car';
  static String get deletedCar => _ro ? 'Mașină ștearsă' : 'Deleted car';
  static String get yourCar => _ro ? 'Mașina ta' : 'Your car';

  // ---------- Home screen ----------
  static String get remindersTooltip => _ro ? 'Remindere' : 'Reminders';
  static String get alertsHeader => _ro ? 'Atenționări' : 'Alerts';
  static String get myCarsHeader => _ro ? 'Mașinile mele' : 'My Cars';
  static String get noCarsYet => _ro
      ? 'Nu ai adăugat nicio mașină încă. Apasă pe + pentru a adăuga prima mașină.'
      : 'You haven\'t added any car yet. Tap + to add your first car.';
  static String get addVehicleDocumentsShortcut => _ro
      ? 'Adaugă RCA / CASCO / ITP / Rovinietă'
      : 'Add insurance / inspection documents';
  static String get houseHeader => _ro ? 'Casă' : 'House';
  static String get addHomeInsurance => _ro
      ? 'Adaugă asigurare locuință / alt document'
      : 'Add home insurance / other document';
  static String get homeLabel => _ro ? 'Locuință' : 'Home';

  // ---------- Vehicle detail screen ----------
  static String get tabInfo => 'Info';
  static String get tabService => _ro ? 'Revizii' : 'Service';
  static String get tabDocuments => _ro ? 'Documente' : 'Documents';
  static String get tabComponents => _ro ? 'Componente' : 'Components';
  static String get carNotFound => _ro ? 'Mașina nu a fost găsită.' : 'Car not found.';
  static String get make => _ro ? 'Marcă' : 'Make';
  static String get model => _ro ? 'Model' : 'Model';
  static String get year => _ro ? 'An fabricație' : 'Year';
  static String get plateNumber => _ro ? 'Nr. înmatriculare' : 'Plate number';
  static String get vin => 'VIN';
  static String get fuelType => _ro ? 'Combustibil' : 'Fuel type';
  static String get engineCode => _ro ? 'Cod motor' : 'Engine code';
  static String get currentMileage => _ro ? 'Kilometraj curent' : 'Current mileage';
  static String get noServiceRecordsYet =>
      _ro ? 'Nicio revizie înregistrată încă.' : 'No service records yet.';
  static String get noDocumentsYet =>
      _ro ? 'Niciun document adăugat încă.' : 'No documents added yet.';

  // ---------- Add/Edit vehicle screen ----------
  static String get editCar => _ro ? 'Editează mașina' : 'Edit car';
  static String get newCar => _ro ? 'Mașină nouă' : 'New car';
  static String get takePhoto => _ro ? 'Fă o poză' : 'Take a photo';
  static String get chooseFromGallery => _ro ? 'Alege din galerie' : 'Choose from gallery';
  static String get readingRegistration =>
      _ro ? 'Se citește talonul...' : 'Reading registration...';
  static String get scanRegistration =>
      _ro ? 'Scanează talonul (completare automată)' : 'Scan registration (auto-fill)';
  static String get carPhoto => _ro ? 'Poză mașină' : 'Car photo';
  static String get nameHint => _ro ? 'Nume (ex: Mașina mea)' : 'Name (e.g. My Car)';
  static String get vinOptional =>
      _ro ? 'Serie șasiu (VIN) — opțional' : 'Chassis number (VIN) — optional';
  static String get fuelTypeOptional => _ro ? 'Combustibil — opțional' : 'Fuel type — optional';
  static String get engineCodeOptional =>
      _ro ? 'Cod motor — opțional' : 'Engine code — optional';
  static String get deleteCarTitle => _ro ? 'Ștergi mașina?' : 'Delete car?';
  static String get deleteCarBody => _ro
      ? 'Se vor șterge și toate reviziile și documentele asociate acestei mașini.'
      : 'All service records and documents linked to this car will also be deleted.';
  static String scanFilledFields(int n) => _ro
      ? 'Am completat $n câmpuri din talon. Verifică și corectează dacă e nevoie.'
      : 'Filled in $n field${n == 1 ? '' : 's'} from the registration. Please review and correct if needed.';
  static String get scanNoData => _ro
      ? 'Nu am putut citi date din poză. Completează câmpurile manual.'
      : 'Couldn\'t read data from the photo. Please fill in the fields manually.';
  static String get scanFailed => _ro
      ? 'Scanarea a eșuat. Completează câmpurile manual.'
      : 'Scan failed. Please fill in the fields manually.';
  static String get decodeEngineFromVin =>
      _ro ? 'Decodifică motor din VIN' : 'Decode engine from VIN';
  static String get vinInvalidFormat => _ro
      ? 'VIN invalid — trebuie să aibă 17 caractere (fără I, O, Q).'
      : 'Invalid VIN — must be 17 characters (no I, O, Q).';
  static String get vinMakeRequired => _ro
      ? 'Completează marca mașinii înainte de decodare.'
      : 'Fill in the make before decoding.';
  static String get vinNoEngineMatches => _ro
      ? 'Nu am găsit motoare în catalog pentru această marcă/model/an. Completează manual codul motorului.'
      : 'No matching engines found in the catalog for this make/model/year. Please fill in the engine code manually.';
  static String vinMakeMismatch(String detected, String typed) => _ro
      ? 'VIN-ul pare să fie de la $detected, dar ai completat marca $typed. Verifică marca — se caută în catalog după $typed.'
      : 'This VIN looks like it\'s from $detected, but you entered $typed as the make. Please double-check — the catalog search uses $typed.';
  static String get vinCandidatesTitleExact =>
      _ro ? 'Motoare posibile (marcă/model/an)' : 'Possible engines (make/model/year)';
  static String get vinCandidatesTitleModel =>
      _ro ? 'Motoare posibile (marcă/model, orice an)' : 'Possible engines (make/model, any year)';
  static String get vinCandidatesTitleMake =>
      _ro ? 'Motoare posibile (doar marcă)' : 'Possible engines (make only)';
  static String get vinCandidatesHint => _ro
      ? 'Alege motorul care corespunde mașinii tale:'
      : 'Choose the engine that matches your car:';
  static String get vinEngineApplied =>
      _ro ? 'Cod motor completat din catalog.' : 'Engine code filled in from the catalog.';
  static String get present => _ro ? 'prezent' : 'present';
  static String vinApproximateMatchHint(int year) => _ro
      ? 'Fără potrivire exactă pentru anul $year — verifică anii afișați la fiecare motor înainte să alegi, pot fi de la o altă generație a modelului.'
      : 'No exact match for year $year — check the years shown for each engine before picking, they may be from a different model generation.';

  // ---------- Add/Edit service record screen ----------
  static String get editServiceRecord => _ro ? 'Editează revizia' : 'Edit service record';
  static String get newServiceRecord => _ro ? 'Revizie nouă' : 'New service record';
  static String get deleteServiceRecordTitle => _ro ? 'Ștergi revizia?' : 'Delete service record?';
  static String get serviceTitleHint => _ro
      ? 'Titlu (ex: Revizie 30.000 km, Schimb plăcuțe frână)'
      : 'Title (e.g. 30,000 km service, Brake pads)';
  static String get mileageAtServiceDate =>
      _ro ? 'Kilometraj la data reviziei' : 'Mileage at service date';
  static String get whatChangedHint =>
      _ro ? 'Ce s-a schimbat / observații' : 'What was changed / notes';
  static String get cost => _ro ? 'Cost (lei)' : 'Cost';
  static String get costOptional => _ro ? 'Cost (lei) — opțional' : 'Cost — optional';
  static String get workshop => _ro ? 'Service auto' : 'Workshop';
  static String get nextServiceReminderHeader =>
      _ro ? 'Reminder pentru revizia următoare (opțional)' : 'Reminder for the next service (optional)';
  static String get nextServiceDate => _ro ? 'Data următoarei revizii' : 'Next service date';
  static String get nextServiceMileage =>
      _ro ? 'Kilometraj următoarea revizie' : 'Next service mileage';
  static String get serviceBookPhoto =>
      _ro ? 'Poză carte service / factură' : 'Service book / invoice photo';
  static String get costUnit => _ro ? 'lei' : '';
  static String get changedComponentsHeader =>
      _ro ? 'Componente schimbate' : 'Changed components';
  static String get changedComponentsHint => _ro
      ? 'Bifează componentele schimbate — se actualizează automat în pagina de componente'
      : 'Check the components you changed — updated automatically on the components page';

  // ---------- Add/Edit document screen ----------
  static String get editDocument => _ro ? 'Editează document' : 'Edit document';
  static String get newDocument => _ro ? 'Document nou' : 'New document';
  static String get deleteDocumentTitle => _ro ? 'Ștergi documentul?' : 'Delete document?';
  static String get documentType => _ro ? 'Tip document' : 'Document type';
  static String get customNameOptional =>
      _ro ? 'Denumire personalizată — opțional' : 'Custom name — optional';
  static String get provider => _ro ? 'Asigurător / furnizor' : 'Provider';
  static String get policyNumber => _ro ? 'Nr. poliță / document' : 'Policy / document number';
  static String get startDateOptional => _ro ? 'Data început — opțional' : 'Start date — optional';
  static String get expiryDate => _ro ? 'Data expirării' : 'Expiry date';
  static String get documentPhoto => _ro ? 'Poză document / poliță' : 'Document / policy photo';
  static String get verifyOnOfficialSite =>
      _ro ? 'Verifică pe site-ul oficial' : 'Check on official site';
  static String get plateNumberLabel => _ro ? 'Nr. înmatriculare' : 'Plate number';
  static String get vinLabel => _ro ? 'Seria VIN' : 'VIN';
  static String verificationValueCopied(String label, String value) => _ro
      ? '$label ($value) copiat — se deschide pagina oficială. Introdu data găsită.'
      : '$label ($value) copied — opening the official page. Enter the date you find.';
  static String verificationValueMissing(String label) => _ro
      ? 'Lipsește "$label" pentru această mașină — introdu-l manual pe pagina oficială.'
      : 'Missing "$label" for this car — enter it manually on the official page.';
  static String verificationAlsoNeedsVin(String vin) =>
      _ro ? 'Ai nevoie și de seria VIN: $vin.' : 'You\'ll also need the VIN: $vin.';
  static String get verificationLaunchFailed =>
      _ro ? 'Nu am putut deschide pagina oficială.' : 'Couldn\'t open the official page.';

  // ---------- Add/Edit reminder screen ----------
  static String get editReminder => _ro ? 'Editează reminder' : 'Edit reminder';
  static String get newReminder => _ro ? 'Reminder nou' : 'New reminder';
  static String get title => _ro ? 'Titlu' : 'Title';
  static String get linkedCarOptional => _ro ? 'Mașină asociată — opțional' : 'Linked car — optional';

  // ---------- Reminders screen ----------
  static String get remindersTitle => _ro ? 'Remindere' : 'Reminders';
  static String get personalReminders => _ro ? 'Remindere personale' : 'Personal reminders';
  static String get noPersonalReminders =>
      _ro ? 'Nu ai niciun reminder personal.' : 'You have no personal reminders.';
  static String get automaticAlerts => _ro ? 'Atenționări automate' : 'Automatic alerts';
  static String get nothingToTrack => _ro ? 'Nimic de urmărit momentan.' : 'Nothing to track right now.';
  static String get reminder => _ro ? 'Reminder' : 'Reminder';

  // ---------- Component tracker ----------
  static String recommendedInterval(String interval) =>
      _ro ? 'Interval recomandat: $interval' : 'Recommended interval: $interval';
  static String get lastChangedDate => _ro ? 'Data ultimei schimbări' : 'Last changed date';
  static String get mileageAtLastChange =>
      _ro ? 'Kilometraj la ultima schimbare' : 'Mileage at last change';
  static String get notSet => _ro ? 'Nesetat' : 'Not set';
  static String get lastChangedPrefix => _ro ? 'Ultima schimbare: ' : 'Last changed: ';
  static String get intervalPrefix => _ro ? 'Interval: ' : 'Interval: ';
  static String get statusOk => 'OK';
  static String get statusDueSoon => _ro ? 'Recomandat curând' : 'Due soon';
  static String get statusOverdue => _ro ? 'Depășit' : 'Overdue';
  static String suggestMaintenanceProfile(String make) =>
      _ro ? 'Sugerează intervale pentru $make' : 'Suggest intervals for $make';
  static String applyMaintenanceProfileTitle(String make) =>
      _ro ? 'Aplici profilul de mentenanță pentru $make?' : 'Apply the maintenance profile for $make?';
  static String applyMaintenanceProfileBody(String displayName) => _ro
      ? 'Se actualizează intervalul de ulei motor/filtru ulei cu valori tipice $displayName și se '
          'adaugă componentele lipsă din listă (ulei cutie de viteze, ștergătoare). Sunt valori '
          'orientative generale, nu date oficiale exacte per model/motorizare — verifică cartea '
          'tehnică a mașinii pentru valorile exacte.'
      : 'Updates the engine oil/oil filter interval with typical $displayName values and adds the '
          'checklist items missing from the list (transmission fluid, wiper blades). These are '
          'general guideline values, not exact official data for your specific model/engine — check '
          'your owner\'s manual for exact figures.';
  static String applyMaintenanceProfileBodyEngine(String displayName, String components) => _ro
      ? 'Se actualizează: $components — cu valorile pentru $displayName. Se adaugă și componentele '
          'lipsă din listă (ulei cutie de viteze, ștergătoare). Date introduse manual (nu cercetate/'
          'verificate de mine) — verifică oricum cartea tehnică a mașinii.'
      : 'Updates: $components — with values for $displayName. Also adds the checklist items missing '
          'from the list (transmission fluid, wiper blades). Manually entered data (not researched/'
          'verified by me) — still check your owner\'s manual.';
  static String applyMaintenanceProfileBodyUnknown(String make) => _ro
      ? 'Nu am un profil specific pentru „$make" — se adaugă doar componentele lipsă din listă '
          '(ulei cutie de viteze, ștergătoare), fără să schimb intervalele existente.'
      : 'No specific profile for "$make" — only adding the checklist items missing from the list '
          '(transmission fluid, wiper blades), without changing existing intervals.';
  static String get apply => _ro ? 'Aplică' : 'Apply';
  static String maintenanceProfileApplied(int updated, int added) => _ro
      ? 'Gata — $updated intervale actualizate, $added componente noi adăugate.'
      : 'Done — $updated intervals updated, $added new components added.';
  static String customIntervalSuffix(String source) =>
      _ro ? ' (profil $source)' : ' ($source profile)';

  // ---------- Document / widgets ----------
  static String get validUntil => _ro ? 'Valabil până la ' : 'Valid until ';
  static String get saveToCalendar => _ro ? 'Salvează în calendar' : 'Save to calendar';
  static String get attachPhoto => _ro ? 'Atașează o poză' : 'Attach a photo';

  // ---------- Date / expiry wording ----------
  static String expiredAgo(int days) =>
      _ro ? 'Expirat de $days ${_zileWord(days)}' : 'Expired $days ${_dayWord(days)} ago';
  static String get expiresToday => _ro ? 'Expiră azi' : 'Expires today';
  static String expiresIn(int days) =>
      _ro ? 'Expiră în $days ${_zileWord(days)}' : 'Expires in $days ${_dayWord(days)}';
  static String _zileWord(int n) => n == 1 ? 'zi' : 'zile';
  static String _dayWord(int n) => n == 1 ? 'day' : 'days';

  // ---------- Alerts ----------
  static String get scheduledService => _ro ? 'Revizie programată' : 'Scheduled service';

  // ---------- Calendar event ----------
  static String calendarEventTitle(String label, String vehicleLabel) =>
      _ro ? '$label expiră — $vehicleLabel' : '$label expires — $vehicleLabel';
  static String get calendarProviderPrefix => _ro ? 'Furnizor: ' : 'Provider: ';
  static String get calendarPolicyPrefix => _ro ? 'Nr. poliță: ' : 'Policy no.: ';

  // ---------- Notifications ----------
  static String get notificationChannelName =>
      _ro ? 'Remindere CarPlanner' : 'CarPlanner Reminders';
  static String get notificationChannelDescription => _ro
      ? 'Notificări pentru revizii, expirări documente și remindere'
      : 'Notifications for service, document expiry and reminders';
  static String documentExpiresInDays(String label, int leadDays) =>
      _ro ? '$label expiră în $leadDays zile' : '$label expires in $leadDays days';
  static String documentExpiresInDaysBody(String label, String vehicleLabel, String date) => _ro
      ? '$label pentru $vehicleLabel expiră pe $date.'
      : '$label for $vehicleLabel expires on $date.';
  static String documentExpiresToday(String label) =>
      _ro ? '$label expiră azi' : '$label expires today';
  static String documentExpiresTodayBody(String label, String vehicleLabel) => _ro
      ? '$label pentru $vehicleLabel expiră astăzi.'
      : '$label for $vehicleLabel expires today.';
  static String get serviceDueSoonTitle => _ro ? 'Revizie programată curând' : 'Service due soon';
  static String serviceDueSoonBody(String vehicleLabel, String date) => _ro
      ? '$vehicleLabel are o revizie programată pe $date.'
      : '$vehicleLabel has a service scheduled on $date.';
  static String get serviceDueTodayTitle => _ro ? 'Revizie azi' : 'Service today';
  static String serviceDueTodayBody(String vehicleLabel) => _ro
      ? '$vehicleLabel are revizia programată astăzi.'
      : '$vehicleLabel has its service scheduled today.';
  static String get genericReminderBody => _ro ? 'Reminder CarPlanner' : 'CarPlanner reminder';

  // ---------- Settings screen ----------
  static String get settingsTitle => _ro ? 'Setări' : 'Settings';
  static String get countryLabel => _ro ? 'Țară' : 'Country';
  static String get countryDescription => _ro
      ? 'Alege țara ta ca să vezi aplicația în limba și cu denumirile de documente potrivite. România păstrează RCA/CASCO/ITP/Rovinietă; orice altă țară primește denumiri generice, în engleză.'
      : 'Choose your country to see the app in the right language and with matching document names. Romania keeps RCA/CASCO/ITP/Rovinietă; any other country gets generic English names.';
  static String get chooseCountry => _ro ? 'Alege țara' : 'Choose country';
  static String get romaniaOptionTitle => 'România';
  static String get romaniaOptionSubtitle =>
      _ro ? 'RCA, CASCO, ITP, Rovinietă' : 'RCA, CASCO, ITP, Rovinietă';
  static String get internationalOptionTitle =>
      _ro ? 'Alte țări (Internațional)' : 'Other countries (International)';
  static String get internationalOptionSubtitle => _ro
      ? 'Denumiri generice, în engleză'
      : 'Generic names, in English';
  static String get futureCountriesNote => _ro
      ? 'Denumiri specifice pentru mai multe țări vor fi adăugate într-o versiune viitoare.'
      : 'Country-specific names for more countries will be added in a future update.';
}
