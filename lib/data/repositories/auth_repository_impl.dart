import 'dart:io';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/conductor_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ConductorEntity>> login(String nroDocumento, String password) async {
    try {
      final conductorModel = await remoteDataSource.login(nroDocumento, password);
      return Either.right(conductorModel.toEntity());
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Either.left(NetworkFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error inesperado: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al cerrar sesión: $e'));
    }
  }

  @override
  Future<Either<Failure, ConductorEntity?>> getLoggedUser() async {
    try {
      final conductorModel = await remoteDataSource.getCurrentUser();
      if (conductorModel != null) {
        return Either.right(conductorModel.toEntity());
      } else {
        return Either.right(null);
      }
    } on CacheException catch (e) {
      return Either.left(CacheFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al obtener usuario: $e'));
    }
  }

  @override
  Future<Either<Failure, ConductorEntity?>> refreshUserData() async {
    try {
      final conductorModel = await remoteDataSource.refreshUserData();
      if (conductorModel != null) {
        return Either.right(conductorModel.toEntity());
      } else {
        return Either.right(null);
      }
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al actualizar datos: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword(String newPassword) async {
    try {
      final result = await remoteDataSource.changePassword(newPassword);
      if (result['success'] == true) {
        return Either.right(null);
      } else {
        return Either.left(ServerFailure(result['message'] ?? 'Error al cambiar contraseña'));
      }
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al actualizar contraseña: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> validateDniForPasswordRecovery(String dni) async {
    try {
      final result = await remoteDataSource.validateDniForPasswordRecovery(dni);
      return Either.right(result);
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al validar DNI: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> resetPassword(String dni, String newPassword) async {
    try {
      final result = await remoteDataSource.resetPassword(dni, newPassword);
      return Either.right(result);
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al resetear contraseña: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadProfilePicture(File imageFile) async {
    try {
      final result = await remoteDataSource.uploadProfilePicture(imageFile);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al subir imagen: $e'));
    }
  }
}
