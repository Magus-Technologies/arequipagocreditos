import '../../core/utils/either.dart';
import '../../core/errors/failures.dart';
import '../entities/financiamiento_entity.dart';
import '../entities/cuota_financiamiento_entity.dart';
import '../repositories/financiamiento_repository.dart';

class GetFinanciamientosUseCase {
  final FinanciamientoRepository repository;

  GetFinanciamientosUseCase({required this.repository});

  Future<Either<Failure, List<FinanciamientoEntity>>> call(int idConductor, int tipo) async {
    return await repository.getFinanciamientos(idConductor, tipo);
  }
}

class GetFinanciamientoByIdUseCase {
  final FinanciamientoRepository repository;

  GetFinanciamientoByIdUseCase({required this.repository});

  Future<Either<Failure, FinanciamientoEntity>> call(int id) async {
    return await repository.getFinanciamientoById(id);
  }
}

class GetCuotasFinanciamientoUseCase {
  final FinanciamientoRepository repository;

  GetCuotasFinanciamientoUseCase({required this.repository});

  Future<Either<Failure, List<CuotaFinanciamientoEntity>>> call(int idFinanciamiento) async {
    return await repository.getCuotasFinanciamiento(idFinanciamiento);
  }
}

class PagarCuotaUseCase {
  final FinanciamientoRepository repository;

  PagarCuotaUseCase({required this.repository});

  Future<Either<Failure, CuotaFinanciamientoEntity>> call(int idCuota, double monto) async {
    // Validaciones de negocio
    if (monto <= 0) {
      return Either.left(const ValidationFailure('El monto debe ser mayor a cero'));
    }
    
    return await repository.pagarCuota(idCuota, monto);
  }
}

class GenerarReporteCuotaUseCase {
  final FinanciamientoRepository repository;

  GenerarReporteCuotaUseCase({required this.repository});

  Future<Either<Failure, String>> call(int idCuota) async {
    return await repository.generarReporteCuota(idCuota);
  }
}
