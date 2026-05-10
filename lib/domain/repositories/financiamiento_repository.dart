import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/financiamiento_entity.dart';
import '../entities/cuota_financiamiento_entity.dart';
import '../entities/documento_firmado_entity.dart';

abstract class FinanciamientoRepository {
  Future<Either<Failure, List<FinanciamientoEntity>>> getFinanciamientos(int idConductor, int tipo);
  Future<Either<Failure, FinanciamientoEntity>> getFinanciamientoById(int id);
  Future<Either<Failure, List<CuotaFinanciamientoEntity>>> getCuotasFinanciamiento(int idFinanciamiento);
  Future<Either<Failure, CuotaFinanciamientoEntity>> pagarCuota(int idCuota, double monto);
  Future<Either<Failure, String>> generarReporteCuota(int idCuota);
  Future<Either<Failure, FinanciamientoEntity>> createFinanciamiento(Map<String, dynamic> data);
  Future<Either<Failure, ListadoDocumentosEntity>> getListadoDocumentosFirmados(int idConductor);
}
