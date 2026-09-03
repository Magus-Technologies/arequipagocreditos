import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/beneficio_entity.dart';
import '../entities/beneficio_servicio_entity.dart';
import '../../data/models/taller_model.dart';

abstract class BeneficiosComercialRepository {
  Future<Either<Failure, List<BeneficioComercialEntity>>> getBeneficiosComerciales({int? tipo, String? audiencia});
  Future<Either<Failure, List<BeneficioServicioEntity>>> getBeneficiosServicios({int? tallerId, String? audiencia, int? clienteConductorId});
  Future<Either<Failure, BeneficioServicioEntity>> getBeneficioDetalle({required int beneficioId, int? clienteConductorId});
  Future<Either<Failure, List<TallerModel>>> getTalleres();
  Future<Either<Failure, TalleresAgrupadosResponse>> getTalleresAgrupados({
    String? audiencia,
    String? departamento,
    String? tipoVehicular,
  });
  Future<Map<String, dynamic>> calificarTaller({required int tallerId, required int clienteConductorId, required int puntuacion, String? comentario, int? financiamientoId});
}