import '../repositories/auth_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String newPassword) async {
    if (newPassword.trim().isEmpty) {
      return Either.left(const ValidationFailure('La contraseña no puede estar vacía'));
    }

    if (newPassword.length < 6) {
      return Either.left(const ValidationFailure('La contraseña debe tener al menos 6 caracteres'));
    }

    return await repository.updatePassword(newPassword);
  }
}
