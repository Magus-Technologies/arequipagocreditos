import 'dart:io';
import '../entities/conductor_entity.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';

abstract class AuthRepository {
  Future<Either<Failure, ConductorEntity>> login(String nroDocumento, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, ConductorEntity?>> getLoggedUser();
  Future<Either<Failure, ConductorEntity?>> refreshUserData();
  Future<Either<Failure, void>> updatePassword(String newPassword);
  Future<Either<Failure, Map<String, dynamic>>> validateDniForPasswordRecovery(String dni);
  Future<Either<Failure, Map<String, dynamic>>> resetPassword(String dni, String newPassword);
  Future<Either<Failure, Map<String, dynamic>>> uploadProfilePicture(File imageFile);
  Future<Either<Failure, Map<String, dynamic>>> updateVehicleData(Map<String, dynamic> data);
  Future<Either<Failure, Map<String, dynamic>>> preRegister(Map<String, dynamic> data, Map<String, File> files);
  Future<Either<Failure, Map<String, dynamic>>> deleteAccount();
}
