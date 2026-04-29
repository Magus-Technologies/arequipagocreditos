import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/repositories/signature_repository.dart';
import '../datasources/signature_remote_datasource.dart';

class SignatureRepositoryImpl implements SignatureRepository {
  final SignatureRemoteDataSource remoteDataSource;

  SignatureRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Map<String, dynamic>>> firmar({
    required String tipo,
    required int id,
    required String firmaBase64,
    required String nroDocumento,
  }) async {
    try {
      final result = await remoteDataSource.firmar(
        tipo: tipo,
        id: id,
        firmaBase64: firmaBase64,
        nroDocumento: nroDocumento,
      );
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
