import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Selector de un catálogo que se carga del servidor (departamento, provincia, distrito) con los mismos estados del registro de
/// conductores: «Cargando…», error con «Toca para reintentar» y, mientras falta elegir el nivel anterior, un aviso en gris.
class CatalogoDropdown extends StatelessWidget {
  const CatalogoDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onChanged,
    this.placeholder,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<String?> onChanged;

  /// Si no es null, el selector se muestra apagado con este texto (p. ej. «Selecciona primero el departamento»).
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Cargando...', style: TextStyle(fontSize: 15, color: Colors.black45)),
            ),
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black45),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.refresh, color: Colors.red.shade400, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error al cargar $label. Toca para reintentar',
                  style: TextStyle(fontSize: 13, color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (placeholder != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Icon(icon, color: Colors.black26, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(placeholder!, style: const TextStyle(fontSize: 14, color: Colors.black38)),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      items: items,
      isExpanded: true,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45),
        prefixIcon: Icon(icon, color: Colors.black87, size: 22),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
    );
  }
}
