import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/strings.dart';

/// Câmp reutilizabil pentru atașarea unei poze (poză carte service, scan
/// document etc). Copiază fișierul ales în directorul de documente al
/// aplicației și întoarce calea locală prin [onChanged].
class PhotoPickerField extends StatefulWidget {
  final String? initialPath;
  final String? label;
  final ValueChanged<String?> onChanged;

  const PhotoPickerField({
    super.key,
    required this.initialPath,
    required this.onChanged,
    this.label,
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

  void _remove() {
    setState(() => _path = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label ?? S.attachPhoto, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (_path != null)
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
            ],
          ),
      ],
    );
  }
}
