import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/strings.dart';

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

  const PhotoPickerField({
    super.key,
    required this.initialPath,
    required this.onChanged,
    this.label,
    this.allowPdf = false,
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
    final result = await FilePicker.platform.pickFiles(
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.openPdfFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label ?? S.attachPhoto, style: Theme.of(context).textTheme.labelLarge),
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
                    icon: const Icon(Icons.close, size: 18, color: Colors.white),
                    onPressed: _remove,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(S.camera),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(S.gallery),
              ),
              if (widget.allowPdf) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(S.attachPdf),
                ),
              ],
            ],
          ),
      ],
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
