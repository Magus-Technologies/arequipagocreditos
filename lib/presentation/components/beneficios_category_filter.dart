import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BeneficiosCategoryFilter extends StatelessWidget {
  final String filtroCategoria;
  final List<String> categorias;
  final ValueChanged<String> onCategoryChanged;

  const BeneficiosCategoryFilter({
    super.key,
    required this.filtroCategoria,
    required this.categorias,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          final isSelected = categoria == filtroCategoria;
          
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(categoria),
              selected: isSelected,
              onSelected: (selected) => onCategoryChanged(categoria),
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppTheme.primary.withAlpha((0.2 * 255).toInt()),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black87 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }
}