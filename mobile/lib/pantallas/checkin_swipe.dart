import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../api.dart';
import '../modelos.dart';
import '../tema.dart';
import 'carta_revelada.dart';

class CheckInSwipePantalla extends StatefulWidget {
  const CheckInSwipePantalla({super.key});

  @override
  State<CheckInSwipePantalla> createState() => _CheckInSwipePantallaState();
}

class _CheckInSwipePantallaState extends State<CheckInSwipePantalla> with SingleTickerProviderStateMixin {
  bool _cargando = true;
  bool _seleccionandoDeporte = true;
  String? _error;
  List<dynamic> _preguntas = [];
  int _indiceActual = 0;
  final Map<String, int> _respuestas = {};
  PerfilModel? _perfil;
  String _deporteSeleccionadoKey = 'bienestar';

  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final perfData = await Api.instancia.get('perfil/');
      final perf = PerfilModel.fromJson(perfData);
      setState(() {
        _perfil = perf;
        _deporteSeleccionadoKey = perf.disciplina;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  Future<void> _confirmarDeporteYSiguiente() async {
    setState(() => _cargando = true);
    try {
      await Api.instancia.put('perfil/', {'disciplina': _deporteSeleccionadoKey});
      final perfData = await Api.instancia.get('perfil/');
      _perfil = PerfilModel.fromJson(perfData);

      final datos = await Api.instancia.get('checkin/preguntas/?disciplina=$_deporteSeleccionadoKey');
      setState(() {
        _preguntas = datos is List ? datos : [];
        _seleccionandoDeporte = false;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  void _responder(int opcionIndex) {
    if (_indiceActual >= _preguntas.length) return;
    final clave = _preguntas[_indiceActual]['clave'] as String;
    _respuestas[clave] = opcionIndex;

    setState(() {
      _dragOffset = Offset.zero;
      _dragAngle = 0.0;
      _indiceActual++;
    });

    if (_indiceActual >= _preguntas.length) {
      _enviarCheckIn();
    }
  }

  void _anteriorPregunta() {
    if (_indiceActual > 0) {
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0.0;
        _indiceActual--;
      });
    } else {
      setState(() {
        _seleccionandoDeporte = true;
      });
    }
  }

  Future<void> _enviarCheckIn() async {
    setState(() => _cargando = true);
    try {
      final res = await Api.instancia.post('checkin/', {'respuestas': _respuestas});
      if (!mounted) return;
      CartaModel? carta;
      if (res is Map && res['carta'] != null) {
        carta = CartaModel.fromJson(res['carta']);
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CartaReveladaPantalla(
            carta: carta,
            indice: res['indice'] ?? 50,
            nivelNombre: res['nivel']?['nombre'] ?? 'Moderado',
          ),
        ),
      );
    } catch (e) {
      try {
        final hoyData = await Api.instancia.get('indice/hoy/');
        if (mounted && hoyData is Map && hoyData['hecho'] == true) {
          CartaModel? carta;
          if (hoyData['carta'] != null) {
            carta = CartaModel.fromJson(hoyData['carta']);
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CartaReveladaPantalla(
                carta: carta,
                indice: hoyData['indice'] ?? 50,
                nivelNombre: hoyData['nivel']?['nombre'] ?? 'Moderado',
              ),
            ),
          );
          return;
        }
      } catch (_) {}

      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return Scaffold(
        backgroundColor: Colores.fondo,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colores.fondo,
        appBar: AppBar(title: const Text('Check-in')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colores.navy)),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
              ],
            ),
          ),
        ),
      );
    }

    if (_seleccionandoDeporte) {
      return Scaffold(
        backgroundColor: Colores.fondo,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('¿Qué disciplina practicas hoy?'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Elige tu deporte para adaptar el tono del coach, las preguntas y las cartas de rendimiento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colores.gris, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildOpcionDeporte(
                            context,
                            key: 'runner',
                            nombre: 'Runner / Atletismo',
                            subtitulo: 'Zancada, tempo run y kilometraje',
                            icono: '🏃',
                            color: Colors.blue.shade100,
                          ),
                          const SizedBox(height: 12),
                          _buildOpcionDeporte(
                            context,
                            key: 'ciclista',
                            nombre: 'Ciclismo / MTB',
                            subtitulo: 'Vatios, cadencia y rutas de montaña',
                            icono: '🚴',
                            color: Colors.orange.shade100,
                          ),
                          const SizedBox(height: 12),
                          _buildOpcionDeporte(
                            context,
                            key: 'crossfitter',
                            nombre: 'CrossFit / HIIT',
                            subtitulo: 'WOD, fuerza máxima y potencia',
                            icono: '🏋️',
                            color: Colors.red.shade100,
                          ),
                          const SizedBox(height: 12),
                          _buildOpcionDeporte(
                            context,
                            key: 'bienestar',
                            nombre: 'Bienestar General',
                            subtitulo: 'Salud, movilidad y equilibrio corporal',
                            icono: '🌱',
                            color: Colors.green.shade100,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colores.azul,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _confirmarDeporteYSiguiente,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar a las preguntas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_indiceActual >= _preguntas.length) {
      return Scaffold(
        backgroundColor: Colores.fondo,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Calculando tu Readiness Index y carta del día...'),
            ],
          ),
        ),
      );
    }

    final pregunta = _preguntas[_indiceActual];
    final opciones = pregunta['opciones'] as List;
    final total = _preguntas.length;
    final claveActual = pregunta['clave'] as String;
    final respuestaPrevia = _respuestas[claveActual];

    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Check-in · ${_perfil?.enfoque ?? "Deportista"}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colores.azul.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_indiceActual + 1} / $total',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colores.azul),
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_indiceActual + 1) / total,
                      backgroundColor: Colors.grey.shade300,
                      color: Colores.azul,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    '👈 Desliza si sientes fatiga  •  👉 Derecha si te sientes óptimo  •  O selecciona tu opción',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanUpdate: (details) {
                          setState(() {
                            _dragOffset += details.delta;
                            _dragAngle = (_dragOffset.dx / 300) * (math.pi / 12);
                          });
                        },
                        onPanEnd: (details) {
                          if (_dragOffset.dx > 90) {
                            _responder(opciones.length - 1);
                          } else if (_dragOffset.dx < -90) {
                            _responder(0);
                          } else {
                            setState(() {
                              _dragOffset = Offset.zero;
                              _dragAngle = 0.0;
                            });
                          }
                        },
                        child: Transform.translate(
                          offset: _dragOffset,
                          child: Transform.rotate(
                            angle: _dragAngle,
                            child: Stack(
                              children: [
                                Card(
                                  elevation: 6,
                                  shadowColor: Colores.navy.withValues(alpha: 0.15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  child: Container(
                                    width: double.infinity,
                                    constraints: const BoxConstraints(maxHeight: 460),
                                    padding: const EdgeInsets.all(24.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      gradient: LinearGradient(
                                        colors: [Colors.white, Colors.blue.shade50.withValues(alpha: 0.5)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colores.azul.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Pregunta ${_indiceActual + 1} de $total',
                                            style: const TextStyle(color: Colores.azul, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          pregunta['texto'] ?? '',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold,
                                            color: Colores.navy,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Column(
                                          children: List.generate(opciones.length, (i) {
                                            final esSeleccionada = respuestaPrevia == i;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius.circular(14),
                                                    onTap: () => _responder(i),
                                                    child: AnimatedContainer(
                                                      duration: const Duration(milliseconds: 200),
                                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                      decoration: BoxDecoration(
                                                        color: esSeleccionada ? Colores.azul.withValues(alpha: 0.12) : Colors.white,
                                                        border: Border.all(
                                                          color: esSeleccionada ? Colores.azul : Colores.azul.withValues(alpha: 0.3),
                                                          width: esSeleccionada ? 2.0 : 1.0,
                                                        ),
                                                        borderRadius: BorderRadius.circular(14),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            opciones[i].toString(),
                                                            style: TextStyle(
                                                              fontSize: 14.5,
                                                              fontWeight: esSeleccionada ? FontWeight.bold : FontWeight.w600,
                                                              color: esSeleccionada ? Colores.azul : Colores.navy,
                                                            ),
                                                          ),
                                                          if (esSeleccionada)
                                                            const Icon(Icons.check_circle, color: Colores.azul, size: 20),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                if (_dragOffset.dx > 40)
                                  Positioned(
                                    top: 40,
                                    left: 30,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('¡FRESCO / OK! 👍', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),

                                if (_dragOffset.dx < -40)
                                  Positioned(
                                    top: 40,
                                    right: 30,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade800,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('⚠️ FATIGA / ALERTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colores.navy,
                            side: const BorderSide(color: Colores.azul, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _anteriorPregunta,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(_indiceActual == 0 ? 'Cambiar Deporte' : 'Pregunta Anterior', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpcionDeporte(
    BuildContext context, {
    required String key,
    required String nombre,
    required String subtitulo,
    required String icono,
    required Color color,
  }) {
    final esSeleccionado = _deporteSeleccionadoKey == key;

    return Card(
      elevation: esSeleccionado ? 4 : 1,
      shadowColor: Colores.navy.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: esSeleccionado ? Colores.azul : Colors.grey.shade200,
          width: esSeleccionado ? 2.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _deporteSeleccionadoKey = key;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(icono, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: esSeleccionado ? Colores.azul : Colores.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (esSeleccionado)
                const Icon(Icons.check_circle, color: Colores.azul, size: 26)
              else
                const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
