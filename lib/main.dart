import 'package:flutter/material.dart';

void main() => runApp(const AplicacionCalculadora());

class AplicacionCalculadora extends StatelessWidget {
  const AplicacionCalculadora({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF12141A),
      ),
      home: const PaginaCalculadora(),
    );
  }
}

enum _Tipo { numero, funcion, operador }

class PaginaCalculadora extends StatefulWidget {
  const PaginaCalculadora({super.key});

  @override
  State<PaginaCalculadora> createState() => _EstadoPaginaCalculadora();
}

class _EstadoPaginaCalculadora extends State<PaginaCalculadora> {
  static const int _maximoDigitos = 12;

  String _pantalla = '0';
  String _expresion = '';
  double? _acumulado;
  String? _operacion;
  bool _nuevaEntrada = true;

  bool get _hayError => _pantalla == 'Error';

  String _formatear(double v) {
    if (v.isNaN || v.isInfinite) return 'Error';
    if (v == 0) return '0';
    final abs = v.abs();
    if (abs >= 1e12 || abs < 1e-9) {
      final s = v.toStringAsExponential(6);
      final partes = s.split('e');
      var mantisa = partes[0];
      if (mantisa.contains('.')) {
        mantisa = mantisa.replaceFirst(RegExp(r'0+$'), '');
        mantisa = mantisa.replaceFirst(RegExp(r'\.$'), '');
      }
      return '${mantisa}e${partes[1]}';
    }
    var s = v.toStringAsFixed(10);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  double _convertir(String s) => double.tryParse(s) ?? 0;

  // logica

  /// devuelve null si hay division por cero
  double? _calcular(double a, double b, String operacion) {
    switch (operacion) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? null : a / b;
    }
    return b;
  }

  void _marcarError() {
    _pantalla = 'Error';
    _expresion = '';
    _acumulado = null;
    _operacion = null;
    _nuevaEntrada = true;
  }

  void _limpiar() {
    setState(() {
      _pantalla = '0';
      _expresion = '';
      _acumulado = null;
      _operacion = null;
      _nuevaEntrada = true;
    });
  }

  void _digito(String d) {
    setState(() {
      if (_hayError) _limpiar();
      if (_nuevaEntrada || _pantalla == '0') {
        _pantalla = d;
        _nuevaEntrada = false;
      } else if (_pantalla.replaceAll(RegExp(r'[-.]'), '').length <
          _maximoDigitos) {
        _pantalla += d;
      }
    });
  }

  void _punto() {
    setState(() {
      if (_hayError) _limpiar();
      if (_nuevaEntrada) {
        _pantalla = '0.';
        _nuevaEntrada = false;
      } else if (!_pantalla.contains('.')) {
        _pantalla += '.';
      }
    });
  }

  void _operador(String operacion) {
    setState(() {
      if (_hayError) return;
      final actual = _convertir(_pantalla);

      if (_acumulado != null && _operacion != null && !_nuevaEntrada) {
        final resultado = _calcular(_acumulado!, actual, _operacion!);
        if (resultado == null) {
          _marcarError();
          return;
        }
        _acumulado = resultado;
        _pantalla = _formatear(resultado);
      } else if (_acumulado == null || _operacion == null) {
        _acumulado = actual;
      }

      _operacion = operacion;
      _nuevaEntrada = true;
      _expresion = '${_formatear(_acumulado!)} $operacion';
    });
  }

  void _igual() {
    setState(() {
      if (_hayError || _acumulado == null || _operacion == null) return;
      final b = _convertir(_pantalla);
      final resultado = _calcular(_acumulado!, b, _operacion!);
      if (resultado == null) {
        _marcarError();
        return;
      }
      _expresion = '${_formatear(_acumulado!)} $_operacion ${_formatear(b)} =';
      _pantalla = _formatear(resultado);
      _acumulado = null;
      _operacion = null;
      _nuevaEntrada = true;
    });
  }

  void _porcentaje() {
    setState(() {
      if (_hayError) return;
      _pantalla = _formatear(_convertir(_pantalla) / 100);
      _nuevaEntrada = true;
    });
  }

  void _borrarUltimo() {
    setState(() {
      if (_hayError) {
        _limpiar();
        return;
      }
      if (_nuevaEntrada) return;
      var s = _pantalla.substring(0, _pantalla.length - 1);
      if (s.isEmpty || s == '-') s = '0';
      _pantalla = s;
    });
  }

  // parte interfaz

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Expanded(flex: 2, child: _construirPantalla()),
              Expanded(flex: 5, child: _construirTeclado()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirPantalla() {
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _expresion,
            style: const TextStyle(fontSize: 22, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              _pantalla.replaceFirst('.', ','),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calcula el tamaño de cada botón para que siempre sean círculos
  /// perfectos (4 columnas x 5 filas) sin importar el tamaño de pantalla.
  Widget _construirTeclado() {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final porAncho = restricciones.maxWidth / 4;
        final porAlto = restricciones.maxHeight / 5;
        final t = porAncho < porAlto ? porAncho : porAlto;

        return Center(
          child: SizedBox(
            width: t * 4,
            height: t * 5,
            child: Column(
              children: [
                _fila(t, [
                  _boton(t, 'AC', _Tipo.funcion, _limpiar),
                  _boton(t, '⌫', _Tipo.funcion, _borrarUltimo),
                  _boton(t, '%', _Tipo.funcion, _porcentaje),
                  _boton(t, '÷', _Tipo.operador, () => _operador('÷')),
                ]),
                _fila(t, [
                  _boton(t, '7', _Tipo.numero, () => _digito('7')),
                  _boton(t, '8', _Tipo.numero, () => _digito('8')),
                  _boton(t, '9', _Tipo.numero, () => _digito('9')),
                  _boton(t, '×', _Tipo.operador, () => _operador('×')),
                ]),
                _fila(t, [
                  _boton(t, '4', _Tipo.numero, () => _digito('4')),
                  _boton(t, '5', _Tipo.numero, () => _digito('5')),
                  _boton(t, '6', _Tipo.numero, () => _digito('6')),
                  _boton(t, '−', _Tipo.operador, () => _operador('−')),
                ]),
                _fila(t, [
                  _boton(t, '1', _Tipo.numero, () => _digito('1')),
                  _boton(t, '2', _Tipo.numero, () => _digito('2')),
                  _boton(t, '3', _Tipo.numero, () => _digito('3')),
                  _boton(t, '+', _Tipo.operador, () => _operador('+')),
                ]),
                _fila(t, [
                  // El 0 ocupa dos columnas.
                  _boton(t, '0', _Tipo.numero, () => _digito('0'), columnas: 2),
                  _boton(t, ',', _Tipo.numero, _punto),
                  _boton(t, '=', _Tipo.operador, _igual),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fila(double t, List<Widget> hijos) {
    return SizedBox(
      height: t,
      child: Row(children: hijos),
    );
  }

  Widget _boton(
    double t,
    String texto,
    _Tipo tipo,
    VoidCallback alPulsar, {
    int columnas = 1,
  }) {
    late final Color fondo;
    late final Color letra;
    switch (tipo) {
      case _Tipo.numero:
        fondo = const Color(0xFF232733);
        letra = Colors.white;
        break;
      case _Tipo.funcion:
        fondo = const Color(0xFF4B5263);
        letra = Colors.white;
        break;
      case _Tipo.operador:
        fondo = const Color(0xFF7C5CFF);
        letra = Colors.white;
        break;
    }

    return SizedBox(
      width: t * columnas,
      height: t,
      child: Padding(
        padding: EdgeInsets.all(t * 0.07),
        child: Material(
          color: fondo,
          // Círculo en los botones normales y "píldora" en el 0.
          shape: columnas == 1 ? const CircleBorder() : const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alPulsar,
            child: Center(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: t * 0.36,
                  fontWeight: FontWeight.w400,
                  color: letra,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
