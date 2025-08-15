import '../entities/conductor_entity.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

abstract class AuthRepository {
  Future<Either<Failure, ConductorEntity>> login(String nroDocumento, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, ConductorEntity?>> getLoggedUser();
  Future<Either<Failure, ConductorEntity>> refreshUserData();
  Future<Either<Failure, void>> updatePassword(String newPassword);
  Future<Either<Failure, void>> resetPassword(String dni, String newPassword);
  Future<Either<Failure, bool>> validateDni(String dni);
  Future<Either<Failure, String>> uploadProfilePicture(String imagePath);
}
