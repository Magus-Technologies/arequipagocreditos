import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../presentation/components/image_picker_modal.dart';

/// Cómo se elige el archivo de un documento: devuelve null si la persona cancela. Se puede reemplazar (pruebas).
typedef ElegirDocumento = Future<File?> Function(BuildContext context, String titulo);

enum _Fuente { camara, galeria, archivo }

/// Cámara, galería o archivos (PDF). Las fotos se reducen para que pesen poco y se lean bien.
Future<File?> elegirDocumentoDelCelular(BuildContext context, String titulo) async {
  final fuente = await showModalBottomSheet<_Fuente>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ImagePickerModal(
      title: titulo,
      onCameraTap: () => Navigator.of(sheetContext).pop(_Fuente.camara),
      onGalleryTap: () => Navigator.of(sheetContext).pop(_Fuente.galeria),
      onFileTap: () => Navigator.of(sheetContext).pop(_Fuente.archivo),
    ),
  );
  if (fuente == null) return null;

  if (fuente == _Fuente.archivo) {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      allowMultiple: false,
    );
    final ruta = resultado?.files.single.path;
    return ruta == null ? null : File(ruta);
  }

  final foto = await ImagePicker().pickImage(
    source: fuente == _Fuente.camara ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 2000,
    maxHeight: 2000,
    imageQuality: 85,
  );
  return foto == null ? null : File(foto.path);
}
