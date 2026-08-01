import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// Câmp reutilizabil pentru atașarea unei poze (poză carte service, scan
/// document etc) sau, opțional ([allowPdf]), a unui fișier PDF. Copiază
/// fișierul ales în directorul de documente al aplicației și întoarce calea
/// locală prin [onChanged] (extensia originală e păstrată, ca UI-ul să poată
/// distinge poză vs. PDF după extensie).
class PhotoPickerField extends StatefulWidget {
  final String? initialPath;
  final String? label;
  final ValueChanged<String?> onChanged;
  final bool allowPdf;

  /// Dacă apelantul chiar rulează OCR pe fișierul ales — poză SAU PDF (vezi
  /// `DocumentScannerService.scanRcaImage`/`scanRcaPdf`/`scanRovinietaImage`/
  /// `scanRovinietaPdf`, apelate doar pentru RCA/Rovinietă din
  /// `add_edit_document_screen.dart`) — controlează dacă TOATE cele trei
  /// butoane (Cameră/Galerie/PDF) se prezintă ca acțiuni de "Scanează..."
  /// (roșu, sare în ochi) sau ca simple butoane de atașare (stil normal).
  /// Fără asta, butoanele ar promite scanare și pentru tipuri de document
  /// (ITP, CASCO etc.) unde nu se întâmplă nimic în afară de atașarea
  /// fișierului — orice fișier poate fi oricum atașat la orice tip de
  /// document, doar eticheta/stilul diferă după caz.
  final bool scansData;

  const PhotoPickerField({
    super.key,
    required this.initialPath,
    required this.onChanged,
    this.label,
    this.allowPdf = false,
    this.scansData = false,
  });

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _path = widget.initialPath;
  }

  bool get _isPdf => _path?.toLowerCase().endsWith('.pdf') == true;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = 'attach_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final savedPath = '${docsDir.path}/$fileName';
    await File(picked.path).copy(savedPath);

    setState(() => _path = savedPath);
    widget.onChanged(savedPath);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = 'attach_${DateTime.now().microsecondsSinceEpoch}.pdf';
    final savedPath = '${docsDir.path}/$fileName';
    await File(pickedPath).copy(savedPath);

    setState(() => _path = savedPath);
    widget.onChanged(savedPath);
  }

  void _remove() {
    setState(() => _path = null);
    widget.onChanged(null);
  }

  Future<void> _openPdf() async {
    if (_path == null) return;
    final result = await OpenFilex.open(_path!);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.openPdfFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label ?? S.attachPhoto,
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (_path != null && _isPdf)
          _PdfPreviewCard(onOpen: _openPdf, onRemove: _remove)
        else if (_path != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_path!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon:
                        const Icon(Icons.close, size: 18, color: Colors.white),
                    onPressed: _remove,
                  ),
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AttachButton(
                scans: widget.scansData,
                icon: Icons.camera_alt_outlined,
                plainLabel: S.camera,
                scanLabel: S.scanFromCamera,
                onPressed: () => _pick(ImageSource.camera),
              ),
              _AttachButton(
                scans: widget.scansData,
                icon: Icons.photo_library_outlined,
                plainLabel: S.gallery,
                scanLabel: S.scanFromGallery,
                onPressed: () => _pick(ImageSource.gallery),
              ),
              if (widget.allowPdf)
                _AttachButton(
                  scans: widget.scansData,
                  icon: Icons.picture_as_pdf_outlined,
                  plainLabel: S.attachPdf,
                  scanLabel: S.scanDataFromPdf,
                  onPressed: _pickPdf,
                ),
            ],
          ),
      ],
    );
  }
}

/// Buton unic pentru Cameră/Galerie/PDF — stilul (roșu, "Scanează...") e
/// identic pe toate trei atunci când [scans] e adevărat, ca utilizatorul să
/// înțeleagă că oricare din cele trei surse declanșează extragerea automată
/// de date (nu doar PDF-ul, ca înainte). Cu [scans] fals, toate rămân simple
/// butoane de atașare.
class _AttachButton extends StatelessWidget {
  final bool scans;
  final IconData icon;
  final String plainLabel;
  final String scanLabel;
  final VoidCallback onPressed;

  const _AttachButton({
    required this.scans,
    required this.icon,
    required this.plainLabel,
    required this.scanLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!scans) {
      return Pressable(
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(plainLabel),
        ),
      );
    }
    return Pressable(
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: kAttentionColor,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(scanLabel),
      ),
    );
  }
}

class _PdfPreviewCard extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _PdfPreviewCard({required this.onOpen, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_outlined),
        title: Text(S.pdfAttachedLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(onPressed: onOpen, child: Text(S.openPdf)),
            IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}
