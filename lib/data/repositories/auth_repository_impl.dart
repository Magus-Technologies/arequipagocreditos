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
      return Either.right(());
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
  Future<Either<Failure, ConductorEntity>> refreshUserData() async {
    try {
      // TODO: Implementar refresh de datos del usuario
      final currentUser = await remoteDataSource.getCurrentUser();
      if (currentUser != null) {
        return Either.right(currentUser.toEntity());
      } else {
        return Either.left(const CacheFailure('No hay usuario logueado'));
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
      // TODO: Implementar actualización de contraseña
      await Future.delayed(const Duration(milliseconds: 500));
      return Either.right(());
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al actualizar contraseña: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String dni, String newPassword) async {
    try {
      // TODO: Implementar reset de contraseña
      await Future.delayed(const Duration(milliseconds: 500));
      return Either.right(());
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al resetear contraseña: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateDni(String dni) async {
    try {
      // TODO: Implementar validación de DNI
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (dni.length != 8 || !RegExp(r'^\d+$').hasMatch(dni)) {
        return Either.right(false);
      }
      
      return Either.right(true);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al validar DNI: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePicture(String imagePath) async {
    try {
      // TODO: Implementar subida de foto de perfil
      await Future.delayed(const Duration(seconds: 2));
      return Either.right('https://example.com/uploaded-image.jpg');
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } catch (e) {
      return Either.left(UnknownFailure('Error al subir imagen: $e'));
    }
  }
}
