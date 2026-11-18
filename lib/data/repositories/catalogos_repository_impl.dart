import 'dart:io';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../domain/repositories/catalogos_repository.dart';
import '../datasources/catalogos_remote_datasource.dart';
import '../models/catalogo_models.dart';
import '../models/conductor_estado_model.dart';
import '../models/izipay_models.dart';
import '../models/verificacion_registro_model.dart';
import '../models/yape_models.dart';

class CatalogosRepositoryImpl implements CatalogosRepository {
  final CatalogosRemoteDataSource remoteDataSource;

  CatalogosRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getDepartamentos() async {
    try {
      final result = await remoteDataSource.getDepartamentos();
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getProvincias(String codigoDepartamento) async {
    try {
      final result = await remoteDataSource.getProvincias(codigoDepartamento);
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UbigeoItemModel>>> getDistritos(String codigoProvincia) async {
    try {
      final result = await remoteDataSource.getDistritos(codigoProvincia);
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlataformaItemModel>>> getPlataformas() async {
    try {
      final result = await remoteDataSource.getPlataformas();
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UbicacionPlataformaModel>> getUbicacionesPlataforma(String plataforma) async {
    try {
      final result = await remoteDataSource.getUbicacionesPlataforma(plataforma);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VerificacionRegistroModel>> verificarRegistroConductor({String? nroDocumento, String? nroLicencia, String? correo}) async {
    try {
      final result = await remoteDataSource.verificarRegistroConductor(nroDocumento: nroDocumento, nroLicencia: nroLicencia, correo: correo);
      return Either.right(result);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConductorEstadoModel>> getConductorEstado(int conductorId) async {
    try {
      final result = await remoteDataSource.getConductorEstado(conductorId);
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ConductorEstadoModel>> generarOrdenCajaArequipa(int clienteId) async {
    try {
      final result = await remoteDataSource.generarOrdenCajaArequipa(clienteId);
      return Either.right(result);
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, InscripcionPagoInfoModel>> getInscripcionPagoInfo({String? plataforma, String? departamento, String? tipo}) async {
    try {
      final result = await remoteDataSource.getInscripcionPagoInfo(plataforma: plataforma, departamento: departamento, tipo: tipo);
      return Either.right(result);
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, IzipayInfoModel>> getIzipayInfo(int clienteId) async {
    try {
      final result = await remoteDataSource.getIzipayInfo(clienteId);
      return Either.right(result);
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> subirCapturaIzipay({
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
    String? numeroOperacion,
  }) async {
    try {
      final result = await remoteDataSource.subirCapturaIzipay(
        clienteConductorId: clienteConductorId,
        nroDocumento: nroDocumento,
        captura: captura,
        numeroOperacion: numeroOperacion,
      );
      return Either.right(result);
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, YapeInscripcionEstadoModel>> getYapeInscripcionEstado({required int clienteId, required String nroDocumento}) {
    return _yape(() => remoteDataSource.getYapeInscripcionEstado(clienteId: clienteId, nroDocumento: nroDocumento));
  }

  @override
  Future<Either<Failure, YapeInscripcionEstadoModel>> afiliarYapeInscripcion({
    required int clienteId,
    required String nroDocumento,
    required String celular,
  }) {
    return _yape(() => remoteDataSource.afiliarYapeInscripcion(clienteId: clienteId, nroDocumento: nroDocumento, celular: celular));
  }

  @override
  Future<Either<Failure, YapeInscripcionEstadoModel>> cobrarYapeInscripcion({required int clienteId, required String nroDocumento}) {
    return _yape(() => remoteDataSource.cobrarYapeInscripcion(clienteId: clienteId, nroDocumento: nroDocumento));
  }

  @override
  Future<Either<Failure, bool>> getYapeAcceso({required String nroDocumento}) async {
    try {
      return Either.right(await remoteDataSource.getYapeAcceso(nroDocumento: nroDocumento));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, YapeInscripcionEstadoModel>> _yape(Future<YapeInscripcionEstadoModel> Function() llamada) async {
    try {
      return Either.right(await llamada());
    } on ValidationException catch (e) {
      return Either.left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Either.left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Either.left(ServerFailure(e.toString()));
    }
  }
}
