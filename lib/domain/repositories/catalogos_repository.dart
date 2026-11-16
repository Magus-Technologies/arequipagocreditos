import 'dart:io';
import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../../data/models/catalogo_models.dart';
import '../../data/models/conductor_estado_model.dart';
import '../../data/models/izipay_models.dart';
import '../../data/models/yape_models.dart';

abstract class CatalogosRepository {
  Future<Either<Failure, List<UbigeoItemModel>>> getDepartamentos();
  Future<Either<Failure, List<UbigeoItemModel>>> getProvincias(String codigoDepartamento);
  Future<Either<Failure, List<UbigeoItemModel>>> getDistritos(String codigoProvincia);
  Future<Either<Failure, List<PlataformaItemModel>>> getPlataformas();
  Future<Either<Failure, ConductorEstadoModel>> getConductorEstado(int conductorId);
  Future<Either<Failure, IzipayInfoModel>> getIzipayInfo(int clienteId);
  Future<Either<Failure, InscripcionPagoInfoModel>> getInscripcionPagoInfo({String? plataforma, String? departamento, String? tipo});
  Future<Either<Failure, ConductorEstadoModel>> generarOrdenCajaArequipa(int clienteId);
  Future<Either<Failure, Map<String, dynamic>>> subirCapturaIzipay({
    required int clienteConductorId,
    required String nroDocumento,
    required File captura,
    String? numeroOperacion,
  });
  Future<Either<Failure, YapeInscripcionEstadoModel>> getYapeInscripcionEstado({required int clienteId, required String nroDocumento});
  Future<Either<Failure, YapeInscripcionEstadoModel>> afiliarYapeInscripcion({
    required int clienteId,
    required String nroDocumento,
    required String celular,
  });
  Future<Either<Failure, YapeInscripcionEstadoModel>> cobrarYapeInscripcion({required int clienteId, required String nroDocumento});
}
