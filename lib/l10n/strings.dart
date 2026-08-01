import '../services/region_service.dart';

/// Toate textele afișate în interfață, în română și engleză. Selectate
/// automat în funcție de țara aleasă în Setări — România păstrează
/// exact comportamentul original (RCA/CASCO/ITP/Rovinietă, în română),
/// orice altă țară primește denumiri generice, internaționale, în engleză.
class S {
  static bool get _ro => RegionService.instance.language == AppLanguage.ro;

  // ---------- General ----------
  static String get appName => 'Auto Calendar';
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

  // ---------- Bottom navigation ----------
  static String get navHome => _ro ? 'Acasă' : 'Home';
  static String get navGarage => _ro ? 'Mașini' : 'Cars';
  static String get navHouse => _ro ? 'Casă' : 'House';
  static String get navCosts => _ro ? 'Costuri' : 'Costs';
  static String get navSettings => _ro ? 'Setări' : 'Settings';

  // ---------- Home screen ----------
  static String get alertsHeader => _ro ? 'Atenționări' : 'Alerts';
  static String get allUpToDate =>
      _ro ? 'Totul e la zi. Nicio atenționare în următoarele 30 de zile.' : 'All up to date. No alerts in the next 30 days.';
  static String get myCarsHeader => _ro ? 'Mașinile mele' : 'My Cars';
  static String get noCarsYet => _ro
      ? 'Nu ai adăugat nicio mașină încă. Apasă pe + pentru a adăuga prima mașină.'
      : 'You haven\'t added any car yet. Tap + to add your first car.';
  static String get addVehicleDocumentsShortcut => _ro
      ? 'Adaugă RCA / CASCO / ITP / Rovinietă'
      : 'Add insurance / inspection documents';
  static String get houseWarningsHeader => _ro ? 'Avertizări casă' : 'House warnings';
  static String get noHouseWarnings => _ro
      ? 'Niciun document de locuință adăugat încă.'
      : 'No home documents added yet.';
  static String get seeAll => _ro ? 'Vezi toate' : 'See all';
  static String get houseHeader => _ro ? 'Casă' : 'House';
  static String get addHomeInsurance => _ro
      ? 'Adaugă asigurare, impozit, verificări sau alt document'
      : 'Add insurance, tax, inspections or other document';
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
      _ro ? 'Completare motorizare!' : 'Fill in engine info!';
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
  static String get itpExpiryFoundTitle =>
      _ro ? 'Dată ITP găsită pe talon' : 'ITP expiry date found on the registration';
  static String itpExpiryFoundBody(String date) => _ro
      ? 'Am găsit o dată de valabilitate ITP: $date. O salvez ca document ITP pentru această mașină?'
      : 'Found an ITP expiry date: $date. Save it as an ITP document for this car?';
  static String get itpExpiryApplied =>
      _ro ? 'Documentul ITP a fost actualizat.' : 'The ITP document was updated.';
  static String get itpExpiryNotFoundTitle =>
      _ro ? 'Data ITP nu a putut fi citită' : 'Could not read the ITP expiry date';
  static String get itpExpiryNotFoundBody => _ro
      ? 'Nu am găsit o dată de valabilitate ITP pe poză (talon vechi, ștampilă scrisă de mână greu lizibilă etc.). Vrei s-o completezi manual acum?'
      : "Could not find an ITP expiry date on the photo (older registration, hard-to-read handwritten stamp, etc.). Want to enter it manually now?";
  static String get itpExpiryEnterManually => _ro ? 'Completează manual' : 'Enter manually';

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
  static String get documentPhotoOrPdf =>
      _ro ? 'Poză sau PDF document / poliță' : 'Document / policy photo or PDF';
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

  // ---------- Reminders (now a Home section) ----------
  static String get personalReminders => _ro ? 'Remindere personale' : 'Personal reminders';
  static String get noPersonalReminders =>
      _ro ? 'Nu ai niciun reminder personal.' : 'You have no personal reminders.';
  static String get automaticAlerts => _ro ? 'Atenționări automate' : 'Automatic alerts';
  static String get nothingToTrack => _ro ? 'Nimic de urmărit momentan.' : 'Nothing to track right now.';
  static String get reminder => _ro ? 'Reminder' : 'Reminder';
  static String get addReminderTooltip => _ro ? 'Adaugă reminder' : 'Add reminder';

  // ---------- Costs & calendar screen ----------
  static String get costsTabLabel => _ro ? 'Costuri' : 'Costs';
  static String get calendarTabLabel => _ro ? 'Calendar' : 'Calendar';
  static String get totalCosts => _ro ? 'Total cheltuieli' : 'Total costs';
  static String get noCostsRecorded => _ro
      ? 'Nicio cheltuială înregistrată încă. Adaugă un cost la o revizie sau un document.'
      : 'No costs recorded yet. Add a cost on a service record or a document.';
  static String get serviceCostsLabel => _ro ? 'Revizii' : 'Service';
  static String get documentCostsLabel => _ro ? 'Documente' : 'Documents';
  static String get noEventsThisMonth =>
      _ro ? 'Nimic programat în luna asta.' : 'Nothing scheduled this month.';
  static String get selectDayHint =>
      _ro ? 'Atinge o zi pentru a vedea ce e programat.' : 'Tap a day to see what\'s scheduled.';
  static String get noEventsThisDay =>
      _ro ? 'Nimic programat în această zi.' : 'Nothing scheduled on this day.';
  static const List<String> _monthsRo = [
    'Ianuarie', 'Februarie', 'Martie', 'Aprilie', 'Mai', 'Iunie',
    'Iulie', 'August', 'Septembrie', 'Octombrie', 'Noiembrie', 'Decembrie',
  ];
  static const List<String> _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static String monthYearLabel(int month, int year) =>
      '${(_ro ? _monthsRo : _monthsEn)[month - 1]} $year';
  static const List<String> _weekdaysRo = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];
  static const List<String> _weekdaysEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static List<String> get weekdayShortLabels => _ro ? _weekdaysRo : _weekdaysEn;

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
  static String get customIntervalKmLabel =>
      _ro ? 'Interval personalizat (km) — opțional' : 'Custom interval (km) — optional';
  static String get customIntervalKmHint => _ro
      ? 'Lasă gol pentru valoarea implicită'
      : 'Leave empty to use the default value';
  static String get customIntervalSourceManual => _ro ? 'manual' : 'manual';

  // ---------- Document / widgets ----------
  static String get validUntil => _ro ? 'Valabil până la ' : 'Valid until ';
  static String get saveToCalendar => _ro ? 'Salvează în calendar' : 'Save to calendar';
  static String get attachPhoto => _ro ? 'Atașează o poză' : 'Attach a photo';
  static String get attachPdf => _ro ? 'Atașează PDF' : 'Attach PDF';
  static String get scanDataFromPdf =>
      _ro ? 'Scanează date din PDF' : 'Scan data from PDF';
  static String get scanFromCamera => _ro ? 'Scanează (Cameră)' : 'Scan (Camera)';
  static String get scanFromGallery => _ro ? 'Scanează (Galerie)' : 'Scan (Gallery)';
  static String get pdfAttachedLabel => _ro ? 'PDF atașat' : 'PDF attached';
  static String get openPdf => _ro ? 'Deschide PDF' : 'Open PDF';
  static String get openPdfFailed =>
      _ro ? 'Nu am putut deschide PDF-ul.' : 'Couldn\'t open the PDF.';
  static String get extractingPdfData =>
      _ro ? 'Se citesc datele din PDF...' : 'Reading data from PDF...';
  static String pdfDataFilled(int count) => _ro
      ? 'Am completat $count ${count == 1 ? 'câmp' : 'câmpuri'} din PDF — verifică datele.'
      : 'Filled $count ${count == 1 ? 'field' : 'fields'} from the PDF — please double-check.';
  static String get pdfDataNotFound =>
      _ro ? 'Nu am găsit date în PDF — completează manual.' : 'No data found in the PDF — please fill in manually.';

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
      _ro ? 'Remindere Auto Calendar' : 'Auto Calendar Reminders';
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
  static String get genericReminderBody =>
      _ro ? 'Reminder Auto Calendar' : 'Auto Calendar reminder';
  static String componentDueSoonTitle(String componentName) =>
      _ro ? '$componentName — recomandat curând' : '$componentName — due soon';
  static String componentDueSoonBody(String componentName, String vehicleLabel) => _ro
      ? '$componentName ($vehicleLabel) se apropie de intervalul recomandat de schimbare.'
      : '$componentName ($vehicleLabel) is approaching its recommended change interval.';
  static String componentOverdueTitle(String componentName) =>
      _ro ? '$componentName — depășit' : '$componentName — overdue';
  static String componentOverdueBody(String componentName, String vehicleLabel) => _ro
      ? '$componentName ($vehicleLabel) a depășit intervalul recomandat de schimbare.'
      : '$componentName ($vehicleLabel) is past its recommended change interval.';
  static String mileageReminderTitle(String vehicleLabel) =>
      _ro ? 'Actualizează kilometrajul — $vehicleLabel' : 'Update mileage — $vehicleLabel';
  static String get mileageReminderBody => _ro
      ? 'Introdu kilometrajul curent ca să vezi statusul la zi al componentelor.'
      : 'Enter the current mileage to keep component statuses up to date.';
  static String get backupReminderTitle =>
      _ro ? 'Ai un backup recent?' : 'Have a recent backup?';
  static String get backupReminderBody => _ro
      ? 'Aplicația nu are cloud — dacă ștergi CarPlanner fără backup, datele se pierd definitiv. Exportă unul din Setări.'
      : "The app has no cloud sync — deleting CarPlanner without a backup loses your data for good. Export one from Settings.";

  // ---------- Settings screen ----------
  static String get settingsTitle => _ro ? 'Setări' : 'Settings';
  static String get languageSectionHeader => _ro ? 'Limbă' : 'Language';
  static String get languageDescription => _ro
      ? 'Alege limba aplicației și denumirile de documente potrivite. Româna păstrează RCA/CASCO/ITP/Rovinietă; Engleza folosește denumiri generice.'
      : 'Choose the app language and matching document names. Romanian keeps RCA/CASCO/ITP/Rovinietă; English uses generic names.';
  static String get romanianLanguageTitle => _ro ? 'Română' : 'Romanian';
  static String get romanianLanguageSubtitle =>
      _ro ? 'RCA, CASCO, ITP, Rovinietă' : 'RCA, CASCO, ITP, Rovinietă';
  static String get englishLanguageTitle => _ro ? 'Engleză' : 'English';
  static String get englishLanguageSubtitle =>
      _ro ? 'Denumiri generice, în engleză' : 'Generic names, in English';
  static String get moreLanguagesNote => _ro
      ? 'Mai multe limbi vor fi adăugate într-o versiune viitoare.'
      : 'More languages will be added in a future update.';
  static String get versionSectionHeader => _ro ? 'Despre' : 'About';
  static String appVersionLabel(String? version) {
    if (version == null) return _ro ? 'Se încarcă...' : 'Loading...';
    return _ro ? 'Versiune $version' : 'Version $version';
  }
  static String get feedbackSectionHeader => _ro ? 'Feedback' : 'Feedback';
  static String get feedbackDescription => _ro
      ? 'Ai găsit o problemă sau ai o sugestie? Trimite-mi un email direct din aplicație.'
      : 'Found a bug or have a suggestion? Send me an email directly from the app.';
  static String get sendFeedbackButton => _ro ? 'Trimite feedback' : 'Send feedback';
  static String get feedbackEmailSubject =>
      _ro ? 'CarPlanner - Feedback' : 'CarPlanner - Feedback';
  static String get feedbackLaunchFailed => _ro
      ? 'Nu am putut deschide aplicația de email.'
      : 'Could not open the email app.';
  static String get sendErrorLogButton =>
      _ro ? 'Trimite jurnal erori' : 'Send error log';
  static String get errorLogDescription => _ro
      ? 'Jurnalul de erori rămâne mereu doar pe telefon — nu se trimite nicăieri automat. Îl poți atașa manual la un email dacă întâmpini o problemă.'
      : 'The error log always stays on the phone only — nothing is sent automatically. You can attach it manually to an email if you run into an issue.';
  static String get noErrorLogEntries =>
      _ro ? 'Niciun jurnal de erori — nu ai avut probleme.' : 'No error log yet — no issues so far.';
  static String get backupSectionHeader => _ro ? 'Backup' : 'Backup';
  static String get backupDescription => _ro
      ? 'Aplicația nu are cloud — dacă ștergi aplicația, datele se pierd. Exportă un backup într-un fișier (îl poți salva în Files, iCloud Drive, email etc.) și importă-l după reinstalare ca să-ți recuperezi datele.'
      : "The app has no cloud sync — deleting it erases your data. Export a backup file (save it to Files, iCloud Drive, email, etc.) and import it after reinstalling to get your data back.";
  static String get exportBackupButton => _ro ? 'Exportă backup' : 'Export backup';
  static String get exportBackupFailed =>
      _ro ? 'Exportul backup-ului a eșuat.' : 'Backup export failed.';
  static String get importBackupButton => _ro ? 'Importă backup' : 'Import backup';
  static String get importBackupConfirmTitle =>
      _ro ? 'Înlocuiești toate datele?' : 'Replace all data?';
  static String get importBackupConfirmBody => _ro
      ? 'Importarea unui backup ȘTERGE toate mașinile, reviziile și documentele existente în aplicație și le înlocuiește cu cele din fișier. Nu poate fi anulată.'
      : 'Importing a backup DELETES every vehicle, service record and document currently in the app and replaces them with the ones from the file. This cannot be undone.';
  static String get importBackupConfirmAction => _ro ? 'Înlocuiește' : 'Replace';
  static String get importBackupSuccess =>
      _ro ? 'Backup importat cu succes.' : 'Backup imported successfully.';
  static String get importBackupFailed => _ro
      ? 'Importul a eșuat — fișierul nu pare a fi un backup CarPlanner valid.'
      : 'Import failed — the file does not look like a valid CarPlanner backup.';
  static String get privacyPolicyButton =>
      _ro ? 'Politica de confidențialitate' : 'Privacy policy';
  static String get privacyPolicyTitle =>
      _ro ? 'Politica de confidențialitate' : 'Privacy policy';
  static String get privacyPolicyBody => _ro ? _privacyPolicyRo : _privacyPolicyEn;

  static const String _privacyPolicyRo = '''
CarPlanner este o aplicație offline. Nu are server/backend propriu și nu trimite automat date către niciun serviciu extern.

Ce date sunt stocate și unde

Toate datele pe care le introduci (mașini, kilometraj, revizii, documente RCA/CASCO/Rovinietă/ITP, remindere, poze și PDF-uri atașate) sunt salvate exclusiv local, pe telefonul tău, într-o bază de date SQLite din storage-ul propriu al aplicației. Nimic din acestea nu este trimis către un server, nu este sincronizat în cloud și nu este accesibil altor aplicații.

Dezinstalarea aplicației șterge definitiv toate aceste date.

Jurnal de erori (local, nu automat)

Aplicația păstrează un jurnal text local cu ultimele erori tehnice întâmpinate, strict pe dispozitiv. Acest jurnal nu este trimis nicăieri automat — poate fi trimis doar dacă tu alegi manual, din Setări → Feedback, să-l atașezi la un email.

Aplicația nu folosește niciun serviciu de analytics sau crash reporting extern (ex. Firebase Crashlytics, Google Analytics) — decizie deliberată, ca să nu părăsească nicio informație dispozitivul fără acțiunea ta explicită.

Permisiuni folosite și de ce

• Cameră/Galerie — pentru fotografierea/scanarea talonului auto și a polițelor RCA/CASCO (OCR pe dispozitiv, procesare 100% locală).
• Calendar (citire/scriere) — doar dacă alegi explicit „Salvează în calendar" pentru un document sau o revizie.
• Notificări — pentru remindere locale (expirare documente, revizii programate, componente de mentenanță).
• Stocare/fișiere — pentru atașarea unui PDF (poliță RCA/CASCO) la un document.

Servicii terțe folosite doar ca „deschide pagina"

Butonul „Verifică pe site-ul oficial" deschide, în browser-ul telefonului, pagina oficială RAR/AIDA/CNAIR — aplicația doar copiază în clipboard un identificator (număr de înmatriculare sau VIN) ca să-l poți lipi tu manual acolo. Aplicația nu transmite nimic direct acestor site-uri.

Contact

Pentru întrebări despre confidențialitate: crdo0809@gmail.com''';

  static const String _privacyPolicyEn = '''
CarPlanner is an offline app. It has no server/backend of its own and does not automatically send data to any external service.

What data is stored, and where

Everything you enter (vehicles, mileage, service history, RCA/CASCO/Road Toll/Technical Inspection documents, reminders, attached photos and PDFs) is saved exclusively on your phone, in a local SQLite database inside the app's own storage. None of it is sent to a server, synced to any cloud, or accessible to other apps.

Uninstalling the app permanently deletes all of this data.

Error log (local only, not sent automatically)

The app keeps a local text log of the last technical errors it encountered, strictly on-device. This log is never sent anywhere automatically — it can only be sent if you manually choose to, from Settings → Feedback, by attaching it to an email.

The app does not use any external analytics or crash-reporting service (e.g. Firebase Crashlytics, Google Analytics) — a deliberate choice so that no information leaves the device without your explicit action.

Permissions used and why

• Camera/Gallery — to photograph/scan the vehicle registration card and RCA/CASCO policies (on-device OCR, 100% local processing).
• Calendar (read/write) — only when you explicitly tap "Save to calendar" for a document or service record.
• Notifications — for local reminders (document expiry, scheduled service, maintenance components).
• Storage/files — to attach a PDF (RCA/CASCO policy) to a document.

Third-party services used only to "open the page"

The "Check on the official site" button opens the official RAR/AIDA/CNAIR page in the phone's browser — the app only copies an identifier (plate number or VIN) to the clipboard so you can paste it there yourself. The app does not transmit anything directly to these sites.

Contact

For privacy questions: crdo0809@gmail.com''';
}
