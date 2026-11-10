import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:flutter/material.dart';
import 'package:arequipagocreditos/presentation/components/info_item.dart';
import 'package:arequipagocreditos/presentation/components/perfil_seccion_card.dart';

class PersonalInfoCard extends StatelessWidget {
  final ConductorModel? conductor;

  const PersonalInfoCard({
    super.key,
    required this.conductor,
  });

  @override
  Widget build(BuildContext context) {
    return PerfilSeccionCard(
      titulo: 'Información personal',
      icono: Icons.person_outline,
      children: [
        InfoItem(
          icon: Icons.phone_outlined,
          label: 'Teléfono',
          value: conductor?.telefono ?? InfoItem.sinDato,
        ),
        InfoItem(
          icon: Icons.mail_outline,
          label: 'Correo',
          value: conductor?.correo ?? InfoItem.sinDato,
        ),
        InfoItem(
          icon: Icons.location_on_outlined,
          label: 'Dirección',
          value: conductor?.direccion ?? InfoItem.sinDato,
        ),
        InfoItem(
          icon: Icons.cake_outlined,
          label: 'Fecha de nacimiento',
          value: fechaLegible(conductor?.fechaNacimiento),
        ),
      ],
    );
  }
}
