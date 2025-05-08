import 'package:flutter/material.dart';
import 'package:arequipagocreditos/models/cuota_financiamiento.dart';

class CuotaCard extends StatelessWidget {
  final CuotaFinanciamiento cuota;

  const CuotaCard({super.key, required this.cuota});

  @override
  Widget build(BuildContext context) {
    bool isPagado = cuota.fechaPago != null;
    Color accentColor = isPagado ? Colors.green : Colors.amber;

    return Card(
      color: Colors.white,
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Cuota ${cuota.numeroCuota}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPagado ? "Pagado" : "Pendiente",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Monto
            Row(
              children: [
                const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "S/. ${cuota.monto}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Fecha de vencimiento
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Text(
                  "Vence: ${cuota.fechaVencimiento}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
