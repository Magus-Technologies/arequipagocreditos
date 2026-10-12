import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/posicion_firma.dart';

abstract class SignatureRepository {
  Future<Either<Failure, Map<String, dynamic>>> firmar({
    required String tipo,
    required int id,
    required String firmaBase64,
    required String nroDocumento,
    PosicionFirma? posicion,
  });
}
