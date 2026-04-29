import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../repositories/signature_repository.dart';

class FirmarUseCase {
  final SignatureRepository repository;

  FirmarUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String tipo,
    required int id,
    required String firmaBase64,
    required String nroDocumento,
  }) async {
    if (firmaBase64.isEmpty) {
      return Either.left(const ValidationFailure('La firma no puede estar vacía'));
    }
    if (nroDocumento.isEmpty) {
      return Either.left(const ValidationFailure('El número de documento es requerido'));
    }
    
    return await repository.firmar(
      tipo: tipo,
      id: id,
      firmaBase64: firmaBase64,
      nroDocumento: nroDocumento,
    );
  }
}
