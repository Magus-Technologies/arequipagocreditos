import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arequipagocreditos/services/api_service.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Selecciona una imagen desde la galería o cámara
  static Future<void> pickImage({
    required ImageSource source,
    required Function(bool) setLoading,
    required VoidCallback onSuccess,
    required Function(String) onError,
    required BuildContext context,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null) {
        setLoading(true);

        File imageFile = File(image.path);
        if (await imageFile.exists()) {
          // Only use context if the widget is still mounted
          if (context.mounted) {
            await _uploadImage(
              imageFile: imageFile,
              setLoading: setLoading,
              onSuccess: onSuccess,
              onError: onError,
              context: context,
            );
          } else {
            setLoading(false);
            onError("Error: El widget ya no está montado");
          }
        } else {
          setLoading(false);
          onError("Error: No se pudo acceder al archivo seleccionado");
        }
      } else {
        setLoading(false);
      }
    } catch (e) {
      setLoading(false);
      onError("Error al seleccionar la imagen: ${e.toString()}");
    }
  }

  /// Selecciona una imagen usando FilePicker
  static Future<void> pickImageWithFilePicker({
    required Function(bool) setLoading,
    required VoidCallback onSuccess,
    required Function(String) onError,
    required BuildContext context,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setLoading(true);

        File imageFile = File(result.files.single.path!);

        if (await imageFile.exists()) {
          if (!context.mounted) return;
          await _uploadImage(
            imageFile: imageFile,
            setLoading: setLoading,
            onSuccess: onSuccess,
            onError: onError,
            context: context,
          );
        } else {
          setLoading(false);
          onError("Error: No se pudo acceder al archivo seleccionado");
        }
      } else {
        setLoading(false);
      }
    } catch (e) {
      setLoading(false);
      onError("Error al seleccionar archivo: ${e.toString()}");
    }
  }

  /// Sube la imagen al servidor
  static Future<void> _uploadImage({
    required File imageFile,
    required Function(bool) setLoading,
    required VoidCallback onSuccess,
    required Function(String) onError,
    required BuildContext context,
  }) async {
    try {
      Map<String, dynamic> result = await ApiService.uploadProfilePicture(
        imageFile,
      );

      setLoading(false);

      if (result['success']) {
        onSuccess();
        if (context.mounted) {
          _showSuccessSnackBar(context, result['message']);
        }
      } else {
        onError(result['message']);
        if (context.mounted) {
          _showErrorSnackBar(context, result['message']);
        }
      }
    } catch (e) {
      setLoading(false);
      onError("Error al subir la imagen: ${e.toString()}");
      if (context.mounted) {
        _showErrorSnackBar(context, "Error al subir la imagen");
      }
    }
  }

  /// Muestra SnackBar de éxito
  static void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Muestra SnackBar de error
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
