import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/documento_firmado_entity.dart';
import '../repositories/financiamiento_repository.dart';

class GetDocumentosFirmadosUseCase {
  final FinanciamientoRepository repository;

  GetDocumentosFirmadosUseCase(this.repository);

  Future<Either<Failure, ListadoDocumentosEntity>> call(int conductorId) async {
    return await repository.getListadoDocumentosFirmados(conductorId);
  }
}
