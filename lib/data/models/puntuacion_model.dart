import '../../domain/entities/puntuacion_entity.dart';
import '../../domain/entities/historial_puntos_entity.dart';
import '../../domain/entities/beneficio_entity.dart';

class PuntuacionModel extends PuntuacionEntity {
  const PuntuacionModel({
    required super.id,
    required super.tipoCliente,
    super.idConductor,
    required super.puntajeActual,
    required super.totalFinanciamientos,
    required super.totalRetrasos,
    required super.fechaActualizacion,
    required super.fechaCreacion,
  });

  factory PuntuacionModel.fromJson(Map<String, dynamic> json) {
    return PuntuacionModel(
      id: json['id'] ?? 0,
      tipoCliente: json['tipo_cliente'] ?? '',
      idConductor: json['id_conductor'],
      puntajeActual: json['puntaje_actual'] ?? 0,
      totalFinanciamientos: json['total_financiamientos'] ?? 0,
      totalRetrasos: json['total_retrasos'] ?? 0,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : DateTime.now(),
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo_cliente': tipoCliente,
      'id_conductor': idConductor,
      'puntaje_actual': puntajeActual,
      'total_financiamientos': totalFinanciamientos,
      'total_retrasos': totalRetrasos,
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  PuntuacionEntity toEntity() => PuntuacionEntity(
        id: id,
        tipoCliente: tipoCliente,
        idConductor: idConductor,
        puntajeActual: puntajeActual,
        totalFinanciamientos: totalFinanciamientos,
        totalRetrasos: totalRetrasos,
        fechaActualizacion: fechaActualizacion,
        fechaCreacion: fechaCreacion,
      );

  PuntuacionModel copyWith({
    int? id,
    String? tipoCliente,
    int? idConductor,
    int? puntajeActual,
    int? totalFinanciamientos,
    int? totalRetrasos,
    DateTime? fechaActualizacion,
    DateTime? fechaCreacion,
  }) {
    return PuntuacionModel(
      id: id ?? this.id,
      tipoCliente: tipoCliente ?? this.tipoCliente,
      idConductor: idConductor ?? this.idConductor,
      puntajeActual: puntajeActual ?? this.puntajeActual,
      totalFinanciamientos: totalFinanciamientos ?? this.totalFinanciamientos,
      totalRetrasos: totalRetrasos ?? this.totalRetrasos,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

class HistorialPuntosModel extends HistorialPuntosEntity {
  const HistorialPuntosModel({
    super.id,
    super.puntajeAnterior,
    super.puntajeNuevo,
    required super.puntosPerdidos,
    required super.motivo,
    required super.fechaReferencia,
    super.numeroCuota,
    super.montoCuota,
    super.fechaVencimiento,
    super.fechaPago,
    super.idFinanciamiento,
    super.nombreProducto,
    required super.estadoCuota,
    required super.origen,
  });

  factory HistorialPuntosModel.fromJson(Map<String, dynamic> json) {
    return HistorialPuntosModel(
      id: json['id'],
      puntajeAnterior: json['puntaje_anterior'],
      puntajeNuevo: json['puntaje_nuevo'],
      puntosPerdidos: json['puntos_perdidos'] ?? 0,
      motivo: json['motivo'] ?? '',
      fechaReferencia: json['fecha_referencia'] != null
          ? DateTime.parse(json['fecha_referencia'])
          : DateTime.now(),
      numeroCuota: json['numero_cuota'],
      montoCuota: json['monto_cuota'],
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.parse(json['fecha_vencimiento'])
          : null,
      fechaPago: json['fecha_pago'] != null ? DateTime.parse(json['fecha_pago']) : null,
      idFinanciamiento: json['idfinanciamiento'],
      nombreProducto: json['nombre_producto'],
      estadoCuota: json['estado_cuota'] ?? '',
      origen: json['origen'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puntaje_anterior': puntajeAnterior,
      'puntaje_nuevo': puntajeNuevo,
      'puntos_perdidos': puntosPerdidos,
      'motivo': motivo,
      'fecha_referencia': fechaReferencia.toIso8601String(),
      'numero_cuota': numeroCuota,
      'monto_cuota': montoCuota,
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'fecha_pago': fechaPago?.toIso8601String(),
      'idfinanciamiento': idFinanciamiento,
      'nombre_producto': nombreProducto,
      'estado_cuota': estadoCuota,
      'origen': origen,
    };
  }

  HistorialPuntosEntity toEntity() => HistorialPuntosEntity(
        id: id,
        puntajeAnterior: puntajeAnterior,
        puntajeNuevo: puntajeNuevo,
        puntosPerdidos: puntosPerdidos,
        motivo: motivo,
        fechaReferencia: fechaReferencia,
        numeroCuota: numeroCuota,
        montoCuota: montoCuota,
        fechaVencimiento: fechaVencimiento,
        fechaPago: fechaPago,
        idFinanciamiento: idFinanciamiento,
        nombreProducto: nombreProducto,
        estadoCuota: estadoCuota,
        origen: origen,
      );
}

class BeneficioModel extends BeneficioEntity {
  const BeneficioModel({
    required super.titulo,
    required super.descripcion,
    required super.icono,
    required super.activo,
  });

  factory BeneficioModel.fromJson(Map<String, dynamic> json) {
    return BeneficioModel(
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      icono: json['icono'] ?? '',
      activo: json['activo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'icono': icono,
      'activo': activo,
    };
  }

  BeneficioEntity toEntity() => BeneficioEntity(
        titulo: titulo,
        descripcion: descripcion,
        icono: icono,
        activo: activo,
      );
}
