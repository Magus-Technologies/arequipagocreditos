import 'package:arequipagocreditos/data/models/resumen_crediticio_model.dart';

abstract class ResumenCrediticioRepository {
  Future<ResumenCrediticio> getResumenCrediticio(int conductorId);
}
