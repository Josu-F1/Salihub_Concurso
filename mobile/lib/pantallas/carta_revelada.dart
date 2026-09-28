import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../modelos.dart';
import '../tema.dart';
import 'coleccion.dart';

class CartaReveladaPantalla extends StatefulWidget {
  const CartaReveladaPantalla({
    super.key,
    required this.carta,
    required this.indice,
    required this.nivelNombre,
  });

  final CartaModel? carta;
  final int indice;
  final String nivelNombre;

  @override
  State<CartaReveladaPantalla> createState() => _CartaReveladaPantallaState();
}

class _CartaReveladaPantallaState extends State<CartaReveladaPantalla> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _mostrandoFrente = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _controller.addListener(() {
      if (_controller.value >= 0.5 && !_mostrandoFrente) {
        setState(() {
          _mostrandoFrente = true;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carta = widget.carta;
    final esDorada = carta?.esDorada ?? false;

    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '¡Carta del Día Desbloqueada!',
          style: TextStyle(
            color: Colores.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (esDorada)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colores.azul,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colores.azul.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 1),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('¡CARTA DESTACADA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final angle = _animation.value * math.pi;
                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle);

                      return Transform(
                        transform: transform,
                        alignment: Alignment.center,
                        child: _mostrandoFrente ? _buildCartaFrente(carta, esDorada) : _buildCartaDorso(),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colores.navy,
                          side: const BorderSide(color: Colores.azul, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ColeccionPantalla()));
                        },
                        icon: const Icon(Icons.style, color: Colores.azul),
                        label: const Text('Ver Mi Colección'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          backgroundColor: Colores.azul,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartaDorso() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 320,
        height: 440,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_open_rounded, size: 64, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                'SaliHub',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartaFrente(CartaModel? carta, bool esDorada) {
    return Transform(
      transform: Matrix4.identity()..rotateY(math.pi),
      alignment: Alignment.center,
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: esDorada
              ? const BorderSide(color: Colores.azul, width: 2.5)
              : BorderSide.none,
        ),
        child: Container(
          width: 320,
          height: 440,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: esDorada
                ? const LinearGradient(
                    colors: [Colors.white, Color(0xFFEBF5FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF0F9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    carta?.icono ?? '⭐',
                    style: const TextStyle(fontSize: 32),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colores.azul.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      carta?.categoria ?? 'General',
                      style: const TextStyle(color: Colores.azul, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    carta?.titulo ?? 'Rendimiento Diario',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colores.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"${carta?.frase ?? ""}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colores.azul.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 18, color: Colores.azul),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Insight Técnico · ${widget.nivelNombre}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colores.navy),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      carta?.insight ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
