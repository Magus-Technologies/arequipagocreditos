import 'dart:io';
import '../entities/conductor_entity.dart';
import '../repositories/auth_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

class LoginUseCase {
  final AuthRepository repository;
  
  LoginUseCase(this.repository);
  
  Future<Either<Failure, ConductorEntity>> call(String nroDocumento, String password) async {
    // Validaciones de negocio
    if (nroDocumento.isEmpty) {
      return Either.left(const ValidationFailure('El número de documento es requerido'));
    }
    
    if (password.isEmpty) {
      return Either.left(const ValidationFailure('La contraseña es requerida'));
    }
    
    if (nroDocumento.length != 15) {
      return Either.left(const ValidationFailure('El DNI debe tener 8 dígitos'));
    }
    
    return await repository.login(nroDocumento, password);
  }
}

class LogoutUseCase {
  final AuthRepository repository;
  
  LogoutUseCase(this.repository);
  
  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}

class GetLoggedUserUseCase {
  final AuthRepository repository;
  
  GetLoggedUserUseCase(this.repository);
  
  Future<Either<Failure, ConductorEntity?>> call() async {
    return await repository.getLoggedUser();
  }
}

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

class RefreshUserDataUseCase {
  final AuthRepository repository;

  RefreshUserDataUseCase(this.repository);

  Future<Either<Failure, ConductorEntity?>> call() async {
    return await repository.refreshUserData();
  }
}

class ValidateDniForPasswordRecoveryUseCase {
  final AuthRepository repository;

  ValidateDniForPasswordRecoveryUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String dni) async {
    if (dni.trim().isEmpty) {
      return Either.left(const ValidationFailure('El DNI es requerido'));
    }

    if (dni.length != 15) {
      return Either.left(const ValidationFailure('El DNI debe tener 8 dígitos'));
    }

    return await repository.validateDniForPasswordRecovery(dni);
  }
}

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String dni, String newPassword) async {
    if (dni.trim().isEmpty) {
      return Either.left(const ValidationFailure('El DNI es requerido'));
    }

    if (dni.length != 15) {
      return Either.left(const ValidationFailure('El DNI debe tener 15 dígitos'));
    }

    if (newPassword.trim().isEmpty) {
      return Either.left(const ValidationFailure('La contraseña no puede estar vacía'));
    }

    if (newPassword.length < 6) {
      return Either.left(const ValidationFailure('La contraseña debe tener al menos 6 caracteres'));
    }

    return await repository.resetPassword(dni, newPassword);
  }
}

class UploadProfilePictureUseCase {
  final AuthRepository repository;

  UploadProfilePictureUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String imagePath) async {
    if (imagePath.trim().isEmpty) {
      return Either.left(const ValidationFailure('La ruta de la imagen es requerida'));
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      return Either.left(const ValidationFailure('El archivo de imagen no existe'));
    }

    return await repository.uploadProfilePicture(file);
  }
}
