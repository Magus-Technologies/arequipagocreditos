import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import 'package:arequipagocreditos/data/datasources/resumen_crediticio_datasource.dart';
import 'package:arequipagocreditos/data/models/resumen_crediticio_model.dart';
import 'package:arequipagocreditos/domain/repositories/resumen_crediticio_repository.dart';

class ResumenCrediticioRepositoryImpl implements ResumenCrediticioRepository {
  final ResumenCrediticioRemoteDataSource remoteDataSource;

   ResumenCrediticioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ResumenCrediticio> getResumenCrediticio(int conductorId, int tipo) async {
    try {
      final resumen = await remoteDataSource.getResumenCrediticio(conductorId, tipo);
      return resumen;
    } on ValidationException catch (e) {
      throw ValidationFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } catch (e) {
      throw UnknownFailure('Error inesperado: $e');
    }
  }
}
