import 'package:arequipagocreditos/data/models/resumen_crediticio_model.dart';
import 'package:arequipagocreditos/domain/repositories/resumen_crediticio_repository.dart';

class GetResumenCrediticioUseCase {
  final ResumenCrediticioRepository repository;
  GetResumenCrediticioUseCase({required this.repository});

  Future<ResumenCrediticio> call(int conductorId) async {
    return await repository.getResumenCrediticio(conductorId);
  }
}
