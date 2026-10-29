/// Símbolo con el que se muestran el precio, la inicial y las cuotas de un beneficio: el de su moneda configurada en el
/// dashboard («$», «S/.»…). Si no tiene, o es soles, «S/» (como se mostraba siempre).
///
/// TK-0414: la pantalla «Cálculo de Pago» decía «S/» fijo aunque el beneficio estuviera en dólares (un GPS de $ 267.80 salía
/// como «S/ 267.80» y, abajo, «Cuota Inicial a pagar: $ 267.80»).
String simboloMonedaBeneficio(String? monedaDelBeneficio, {String? monedaDeLaVariante}) {
  final crudo = (monedaDeLaVariante ?? '').trim().isNotEmpty ? monedaDeLaVariante!.trim() : (monedaDelBeneficio ?? '').trim();
  if (crudo.isEmpty || crudo.toUpperCase().startsWith('S/')) return 'S/';
  return crudo;
}
