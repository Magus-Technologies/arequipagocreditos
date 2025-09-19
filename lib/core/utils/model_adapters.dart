import 'package:arequipagocreditos/data/models/puntuacion_model.dart';

import '../../domain/entities/conductor_entity.dart';
import '../../domain/entities/cupon_entity.dart';
import '../../domain/entities/financiamiento_entity.dart';
import '../../domain/entities/cuota_financiamiento_entity.dart';
import '../../domain/entities/puntuacion_entity.dart';
import '../../domain/entities/historial_puntos_entity.dart';

// Modelos legacy para compatibilidad hacia atrás
import 'package:arequipagocreditos/data/models/conductor_model.dart';
import 'package:arequipagocreditos/data/models/cupon_model.dart';
import 'package:arequipagocreditos/data/models/financiamiento_model.dart';
import 'package:arequipagocreditos/data/models/cuota_financiamiento_model.dart';

class ModelAdapters {
  /// Convierte un ConductorEntity a Conductor para compatibilidad con componentes legacy
  static ConductorModel conductorEntityToModel(ConductorEntity entity) {
    return ConductorModel(
      idConductor: entity.idConductor,
      nombres: entity.nombreCompleto,
      nroDocumento: entity.nroDocumento,
      telefono: entity.telefono,
      direccion: entity.direccion,
      correo: entity.correo,
      flag: entity.flag,
      tipo: entity.tipo,
      fotoPerfil: entity.fotoPerfil,
      fotoPerfilCambiada: entity.fotoPerfilCambiada,
    );
  }

  /// Convierte un CuponEntity a Cupon para compatibilidad con componentes legacy
  static CuponModel cuponEntityToModel(CuponEntity entity) {
    return CuponModel(
      id: entity.id,
      titulo: entity.titulo,
      descripcion: entity.descripcion,
      categoria: entity.categoria,
      valor: entity.valor,
      tipoDescuento: entity.tipoDescuento,
      codigo: entity.codigo,
      fechaFin: entity.fechaFin,
      imagenBanner: entity.imagenBanner,
      empresa: entity.empresa,
      condiciones: entity.condiciones,
      limiteUsosConductor: entity.limiteUsosConductor,
      usosRealizados: entity.usosRealizados,
      puedeUsar: entity.puedeUsar,
      estado: entity.estado,
      fechaAsignacion: entity.fechaAsignacion,
      esActivo: true,
    );
  }

  /// Convierte un FinanciamientoEntity a Financiamiento para compatibilidad con componentes legacy
  static FinanciamientoModel financiamientoEntityToModel(
    FinanciamientoEntity entity,
  ) {
    return FinanciamientoModel(
      idFinanciamiento: entity.idFinanciamiento,
      idConductor: entity.idConductor,
      idProducto: entity.idProducto,
      idCoti: entity.idCoti,
      codigoAsociado: entity.codigoAsociado,
      grupoFinanciamiento: entity.grupoFinanciamiento,
      cantidadProducto: entity.cantidadProducto,
      montoTotal: entity.montoTotal,
      cuotaInicial: entity.cuotaInicial,
      cuotas: entity.cuotas,
      estado: entity.estado,
      fechaInicio: entity.fechaInicio,
      fechaFin: entity.fechaFin,
      fechaCreacion: entity.fechaCreacion,
      frecuencia: entity.frecuencia,
      secondProduct: entity.secondProduct,
      moneda: entity.moneda,
    );
  }

  /// Convierte un CuotaFinanciamientoEntity a CuotaFinanciamiento para compatibilidad con componentes legacy
  static CuotaFinanciamientoModel cuotaFinanciamientoEntityToModel(
    CuotaFinanciamientoEntity entity,
  ) {
    return CuotaFinanciamientoModel(
      id: entity.id,
      idFinanciamiento: entity.idFinanciamiento,
      numeroCuota: entity.numeroCuota,
      monto: entity.monto,
      fechaVencimiento: entity.fechaVencimiento,
      estado: entity.estado,
      fechaPago: entity.fechaPago,
      idPago: entity.idPago,
    );
  }

  /// Convierte un PuntuacionEntity a PuntuacionCredito para compatibilidad con componentes legacy
  static PuntuacionModel puntuacionEntityToModel(PuntuacionEntity entity) {
    return PuntuacionModel(
      id: entity.id,
      tipoCliente: entity.tipoCliente,
      idConductor: entity.idConductor,
      puntajeActual: entity.puntajeActual,
      totalFinanciamientos: entity.totalFinanciamientos,
      totalRetrasos: entity.totalRetrasos,
      fechaActualizacion: entity.fechaActualizacion,
      fechaCreacion: entity.fechaCreacion,
    );
  }

  /// Convierte un HistorialPuntosEntity a HistorialPuntos para compatibilidad con componentes legacy
  static HistorialPuntosModel historialPuntosEntityToModel(
    HistorialPuntosEntity entity,
  ) {
    return HistorialPuntosModel(
      id: entity.id,
      puntajeAnterior: entity.puntajeAnterior,
      puntajeNuevo: entity.puntajeNuevo,
      puntosPerdidos: entity.puntosPerdidos,
      motivo: entity.motivo,
      fechaReferencia: entity.fechaReferencia,
      numeroCuota: entity.numeroCuota,
      montoCuota: entity.montoCuota,
      fechaVencimiento: entity.fechaVencimiento,
      fechaPago: entity.fechaPago,
      idFinanciamiento: entity.idFinanciamiento,
      nombreProducto: entity.nombreProducto,
      estadoCuota: entity.estadoCuota,
      origen: entity.origen,
    );
  }

  /// Convierte listas de entidades a modelos legacy
  static List<CuponModel> cuponEntitiesToModels(List<CuponEntity> entities) {
    return entities.map((entity) => cuponEntityToModel(entity)).toList();
  }

  static List<FinanciamientoModel> financiamientoEntitiesToModels(
    List<FinanciamientoEntity> entities,
  ) {
    return entities
        .map((entity) => financiamientoEntityToModel(entity))
        .toList();
  }

  static List<CuotaFinanciamientoModel> cuotaFinanciamientoEntitiesToModels(
    List<CuotaFinanciamientoEntity> entities,
  ) {
    return entities
        .map((entity) => cuotaFinanciamientoEntityToModel(entity))
        .toList();
  }

  static List<HistorialPuntosModel> historialPuntosEntitiesToModels(
    List<HistorialPuntosEntity> entities,
  ) {
    return entities
        .map((entity) => historialPuntosEntityToModel(entity))
        .toList();
  }
}
