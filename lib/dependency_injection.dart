import 'package:arequipagocreditos/data/datasources/resumen_crediticio_datasource.dart';
import 'package:arequipagocreditos/domain/repositories/resumen_crediticio_repository.dart';
import 'package:arequipagocreditos/data/repositories/resumen_crediticio_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// Data Layer
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/cupones_remote_datasource.dart';
import 'data/datasources/cupones_public_remote_datasource.dart';
import 'data/datasources/financiamiento_remote_datasource.dart';
import 'data/datasources/puntuacion_remote_datasource.dart';
import 'data/datasources/beneficios_comercial_remote_datasource.dart';
import 'data/datasources/signature_remote_datasource.dart';
import 'data/datasources/catalogos_remote_datasource.dart';
import 'data/datasources/ordenes_pago_remote_datasource.dart';
import 'data/datasources/nivel_taller_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/cupones_repository_impl.dart';
import 'data/repositories/cupones_public_repository_impl.dart';
import 'data/repositories/financiamiento_repository_impl.dart';
import 'data/repositories/puntuacion_repository_impl.dart';
import 'data/repositories/beneficios_comercial_repository_impl.dart';
import 'data/repositories/signature_repository_impl.dart';
import 'data/repositories/catalogos_repository_impl.dart';
import 'data/repositories/ordenes_pago_repository_impl.dart';
import 'data/repositories/nivel_taller_repository_impl.dart';

// Domain Layer
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/cupones_repository.dart';
import 'domain/repositories/cupones_public_repository.dart';
import 'domain/repositories/financiamiento_repository.dart';
import 'domain/repositories/puntuacion_repository.dart';
import 'domain/repositories/beneficios_comercial_repository.dart';
import 'domain/repositories/signature_repository.dart';
import 'domain/repositories/catalogos_repository.dart';
import 'domain/repositories/ordenes_pago_repository.dart';
import 'domain/repositories/nivel_taller_repository.dart';
import 'domain/usecases/auth_usecases.dart';
import 'domain/usecases/cupones_usecases.dart';
import 'domain/usecases/get_public_cupones_usecase.dart';
import 'domain/usecases/financiamiento_usecases.dart';
import 'domain/usecases/puntuacion_usecases.dart';
import 'domain/usecases/get_resumen_crediticio_usecase.dart';
import 'domain/usecases/get_beneficios_comercial_usecase.dart';
import 'domain/usecases/signature_usecases.dart';
import 'domain/usecases/create_financiamiento_usecase.dart';
import 'domain/usecases/get_beneficios_servicios_usecase.dart';
import 'domain/usecases/get_documentos_firmados_usecase.dart';
import 'domain/usecases/get_ordenes_pago_usecase.dart';
import 'domain/usecases/get_nivel_taller_usecase.dart';

// Presentation Layer
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/cupones_provider.dart';
import 'presentation/providers/cupones_public_provider.dart';
import 'presentation/providers/financiamiento_provider.dart';
import 'presentation/providers/puntuacion_provider.dart';
import 'presentation/providers/resumen_crediticio_provider.dart';
import 'presentation/providers/beneficios_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/signature_provider.dart';
import 'presentation/providers/financiamiento_servicio_provider.dart';
import 'presentation/providers/catalogos_provider.dart';
import 'presentation/providers/ordenes_pago_provider.dart';
import 'presentation/providers/nivel_taller_provider.dart';

class DependencyInjection {
  static List<ChangeNotifierProvider> get providers => [
    // Providers
    ChangeNotifierProvider<AuthProvider>(
      create:
          (context) => AuthProvider(
            loginUseCase: _getLoginUseCase(),
            logoutUseCase: _getLogoutUseCase(),
            getLoggedUserUseCase: _getLoggedUserUseCase(),
            changePasswordUseCase: _getChangePasswordUseCase(),
            validateDniForPasswordRecoveryUseCase:
                validateDniForPasswordRecoveryUseCase(),
            updateVehicleDataUseCase: _getUpdateVehicleDataUseCase(),
            refreshUserDataUseCase: refreshUserDataUseCase(),
            preRegisterUseCase: _getPreRegisterUseCase(),
            conductorPreRegisterUseCase: _getConductorPreRegisterUseCase(),
            deleteAccountUseCase: _getDeleteAccountUseCase(),
          ),
    ),

    ChangeNotifierProvider<CuponesProvider>(
      create:
          (context) => CuponesProvider(
            getCuponesUseCase: _getCuponesUseCase(),
            usarCuponUseCase: _getUsarCuponUseCase(),
            filterCuponesByCategoria: _getFilterCuponesByCategoria(),
          ),
    ),

    ChangeNotifierProvider<FinanciamientoProvider>(
      create:
          (context) => FinanciamientoProvider(
            getFinanciamientosUseCase: getFinanciamientosUseCase(),
            getFinanciamientoByIdUseCase: getFinanciamientoByIdUseCase(),
            getCuotasFinanciamientoUseCase: getCuotasFinanciamientoUseCase(),
            pagarCuotaUseCase: getPagarCuotaUseCase(),
            generarReporteCuotaUseCase: getGenerarReporteCuotaUseCase(),
          ),
    ),

    ChangeNotifierProvider<PuntuacionProvider>(
      create:
          (context) => PuntuacionProvider(
            getPuntuacionUseCase: getPuntuacionUseCase(),
            getHistorialPuntosUseCase: getHistorialPuntosUseCase(),
            getBeneficiosUseCase: getBeneficiosUseCase(),
            actualizarPuntuacionUseCase: getActualizarPuntuacionUseCase(),
          ),
    ),

    ChangeNotifierProvider<ResumenCrediticioProvider>(
      create:
          (context) => ResumenCrediticioProvider(
            getResumenCrediticioUseCase: getResumenCrediticioUseCase(),
          ),
    ),

    ChangeNotifierProvider<BeneficiosProvider>(
      create:
          (context) => BeneficiosProvider(
            getBeneficiosComercialUseCase: getBeneficiosComercialUseCase(),
          ),
    ),
    ChangeNotifierProvider<CuponesPublicProvider>(
      create:
          (context) => CuponesPublicProvider(
            getPublicCuponesUseCase: _getPublicCuponesUseCase(),
          ),
    ),
    ChangeNotifierProvider<NotificationProvider>(
      create: (context) => NotificationProvider(),
    ),
    ChangeNotifierProvider<SignatureProvider>(
      create: (context) => SignatureProvider(
        firmarUseCase: _getFirmarUseCase(),
      ),
    ),
    ChangeNotifierProvider<FinanciamientoServicioProvider>(
      create: (context) => FinanciamientoServicioProvider(
        getBeneficiosServiciosUseCase: _getGetBeneficiosServiciosUseCase(),
        createFinanciamientoUseCase: _getCreateFinanciamientoUseCase(),
        getDocumentosFirmadosUseCase: _getGetDocumentosFirmadosUseCase(),
        beneficiosRepository: _beneficiosComercialRepository,
      ),
    ),
    ChangeNotifierProvider<CatalogosProvider>(
      create: (context) => CatalogosProvider(
        catalogosRepository: _catalogosRepository,
      ),
    ),
    ChangeNotifierProvider<OrdenesPagoProvider>(
      create: (context) => OrdenesPagoProvider(
        getOrdenesPagoUseCase: _getGetOrdenesPagoUseCase(),
      ),
    ),
    ChangeNotifierProvider<NivelTallerProvider>(
      create: (context) => NivelTallerProvider(
        getNivelTallerUseCase: _getGetNivelTallerUseCase(),
      ),
    ),
  ];

  // Repositories
  static AuthRepository get _authRepository =>
      AuthRepositoryImpl(remoteDataSource: _authRemoteDataSource);

  static CuponesRepository get _cuponesRepository =>
      CuponesRepositoryImpl(remoteDataSource: _cuponesRemoteDataSource);

  static CuponesPublicRepository get _cuponesPublicRepository =>
      CuponesPublicRepositoryImpl(
        remoteDataSource: _cuponesPublicRemoteDataSource,
      );

  static FinanciamientoRepository get _financiamientoRepository =>
      FinanciamientoRepositoryImpl(
        remoteDataSource: _financiamientoRemoteDataSource,
      );

  static PuntuacionRepository get _puntuacionRepository =>
      PuntuacionRepositoryImpl(remoteDataSource: _puntuacionRemoteDataSource);

  static ResumenCrediticioRepository get _resumenCrediticioRepository =>
      ResumenCrediticioRepositoryImpl(
        remoteDataSource: _resumenCrediticioRemoteDataSource,
      );

  static BeneficiosComercialRepository get _beneficiosComercialRepository =>
      BeneficiosComercialRepositoryImpl(
        remoteDataSource: _beneficiosComercialRemoteDataSource,
      );

  static SignatureRepository get _signatureRepository =>
      SignatureRepositoryImpl(remoteDataSource: _signatureRemoteDataSource);

  static CatalogosRepository get _catalogosRepository =>
      CatalogosRepositoryImpl(remoteDataSource: _catalogosRemoteDataSource);

  static OrdenesPagoRepository get _ordenesPagoRepository =>
      OrdenesPagoRepositoryImpl(remoteDataSource: _ordenesPagoRemoteDataSource);

  static NivelTallerRepository get _nivelTallerRepository =>
      NivelTallerRepositoryImpl(remoteDataSource: _nivelTallerRemoteDataSource);

  // DataSources
  static AuthRemoteDataSource get _authRemoteDataSource =>
      AuthRemoteDataSourceImpl(client: _httpClient);

  static CuponesRemoteDataSource get _cuponesRemoteDataSource =>
      CuponesRemoteDataSourceImpl(client: _httpClient);

  static CuponesPublicRemoteDataSource get _cuponesPublicRemoteDataSource =>
      CuponesPublicRemoteDataSourceImpl(client: _httpClient);

  static FinanciamientoRemoteDataSource get _financiamientoRemoteDataSource =>
      FinanciamientoRemoteDataSourceImpl(client: _httpClient);

  static PuntuacionRemoteDataSource get _puntuacionRemoteDataSource =>
      PuntuacionRemoteDataSourceImpl(client: _httpClient);

  static ResumenCrediticioRemoteDataSource
  get _resumenCrediticioRemoteDataSource =>
      ResumenRemoteDataSourceImpl(client: _httpClient);

  static BeneficiosComercialRemoteDataSource
  get _beneficiosComercialRemoteDataSource =>
      BeneficiosComercialRemoteDataSourceImpl(client: _httpClient);

  static SignatureRemoteDataSource get _signatureRemoteDataSource =>
      SignatureRemoteDataSourceImpl(client: _httpClient);

  static CatalogosRemoteDataSource get _catalogosRemoteDataSource =>
      CatalogosRemoteDataSourceImpl(client: _httpClient);

  static OrdenesPagoRemoteDataSource get _ordenesPagoRemoteDataSource =>
      OrdenesPagoRemoteDataSourceImpl(client: _httpClient);

  static NivelTallerRemoteDataSource get _nivelTallerRemoteDataSource =>
      NivelTallerRemoteDataSourceImpl(client: _httpClient);

  // Network
  static http.Client get _httpClient => http.Client();

  // Use Cases - Auth
  static LoginUseCase _getLoginUseCase() => LoginUseCase(_authRepository);
  static LogoutUseCase _getLogoutUseCase() => LogoutUseCase(_authRepository);
  static GetLoggedUserUseCase _getLoggedUserUseCase() =>
      GetLoggedUserUseCase(_authRepository);
  static ChangePasswordUseCase _getChangePasswordUseCase() =>
      ChangePasswordUseCase(_authRepository);
  static RefreshUserDataUseCase refreshUserDataUseCase() =>
      RefreshUserDataUseCase(_authRepository);
  static ValidateDniForPasswordRecoveryUseCase
  validateDniForPasswordRecoveryUseCase() =>
      ValidateDniForPasswordRecoveryUseCase(_authRepository);
  static ResetPasswordUseCase resetPasswordUseCase() =>
      ResetPasswordUseCase(_authRepository);
  static UploadProfilePictureUseCase uploadProfilePictureUseCase() =>
      UploadProfilePictureUseCase(_authRepository);
  static UpdateVehicleDataUseCase _getUpdateVehicleDataUseCase() =>
      UpdateVehicleDataUseCase(_authRepository);
  static PreRegisterUseCase _getPreRegisterUseCase() =>
      PreRegisterUseCase(_authRepository);
  static ConductorPreRegisterUseCase _getConductorPreRegisterUseCase() =>
      ConductorPreRegisterUseCase(_authRepository);
  static DeleteAccountUseCase _getDeleteAccountUseCase() =>
      DeleteAccountUseCase(_authRepository);

  // Use Cases - Cupones
  static GetCuponesUseCase _getCuponesUseCase() =>
      GetCuponesUseCase(_cuponesRepository);
  static UsarCuponUseCase _getUsarCuponUseCase() =>
      UsarCuponUseCase(_cuponesRepository);
  static FilterCuponesByCategoria _getFilterCuponesByCategoria() =>
      FilterCuponesByCategoria();
  static GetPublicCuponesUseCase _getPublicCuponesUseCase() =>
      GetPublicCuponesUseCase(_cuponesPublicRepository);

  // Use Cases - Financiamiento
  static GetFinanciamientosUseCase getFinanciamientosUseCase() =>
      GetFinanciamientosUseCase(repository: _financiamientoRepository);
  static GetFinanciamientoByIdUseCase getFinanciamientoByIdUseCase() =>
      GetFinanciamientoByIdUseCase(repository: _financiamientoRepository);
  static GetCuotasFinanciamientoUseCase getCuotasFinanciamientoUseCase() =>
      GetCuotasFinanciamientoUseCase(repository: _financiamientoRepository);
  static PagarCuotaUseCase getPagarCuotaUseCase() =>
      PagarCuotaUseCase(repository: _financiamientoRepository);
  static GenerarReporteCuotaUseCase getGenerarReporteCuotaUseCase() =>
      GenerarReporteCuotaUseCase(repository: _financiamientoRepository);

  // Use Cases - Puntuación
  static GetPuntuacionUseCase getPuntuacionUseCase() =>
      GetPuntuacionUseCase(repository: _puntuacionRepository);
  static GetHistorialPuntosUseCase getHistorialPuntosUseCase() =>
      GetHistorialPuntosUseCase(repository: _puntuacionRepository);
  static GetBeneficiosUseCase getBeneficiosUseCase() =>
      GetBeneficiosUseCase(repository: _puntuacionRepository);
  static ActualizarPuntuacionUseCase getActualizarPuntuacionUseCase() =>
      ActualizarPuntuacionUseCase(repository: _puntuacionRepository);

  // Use Cases - Resumen Crediticio
  static GetResumenCrediticioUseCase getResumenCrediticioUseCase() =>
      GetResumenCrediticioUseCase(repository: _resumenCrediticioRepository);

  // Use Cases - Beneficios Comerciales
  static GetBeneficiosComercialUseCase getBeneficiosComercialUseCase() =>
      GetBeneficiosComercialUseCase(_beneficiosComercialRepository);

  // Use Cases - Signature
  static FirmarUseCase _getFirmarUseCase() =>
      FirmarUseCase(_signatureRepository);

  static GetBeneficiosServiciosUseCase _getGetBeneficiosServiciosUseCase() =>
      GetBeneficiosServiciosUseCase(_beneficiosComercialRepository);

  static CreateFinanciamientoUseCase _getCreateFinanciamientoUseCase() =>
      CreateFinanciamientoUseCase(_financiamientoRepository);

  static GetDocumentosFirmadosUseCase _getGetDocumentosFirmadosUseCase() =>
      GetDocumentosFirmadosUseCase(_financiamientoRepository);

  // Use Cases - Órdenes de pago
  static GetOrdenesPagoUseCase _getGetOrdenesPagoUseCase() =>
      GetOrdenesPagoUseCase(_ordenesPagoRepository);

  // Use Cases - Nivel de talleres
  static GetNivelTallerUseCase _getGetNivelTallerUseCase() =>
      GetNivelTallerUseCase(_nivelTallerRepository);
}
