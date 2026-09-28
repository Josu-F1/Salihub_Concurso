class CartaModel {
  CartaModel({
    required this.codigo,
    required this.disciplina,
    required this.nivel,
    required this.titulo,
    required this.frase,
    required this.insight,
    required this.categoria,
    required this.icono,
    required this.esDorada,
    required this.fecha,
  });

  factory CartaModel.fromJson(Map<String, dynamic> json) {
    return CartaModel(
      codigo: json['codigo'] ?? '',
      disciplina: json['disciplina'] ?? 'bienestar',
      nivel: json['nivel'] ?? 'moderada',
      titulo: json['titulo'] ?? 'Carta de Rendimiento',
      frase: json['frase'] ?? '',
      insight: json['insight'] ?? '',
      categoria: json['categoria'] ?? 'General',
      icono: json['icono'] ?? '⭐',
      esDorada: json['es_dorada'] ?? false,
      fecha: json['fecha'] ?? '',
    );
  }

  final String codigo;
  final String disciplina;
  final String nivel;
  final String titulo;
  final String frase;
  final String insight;
  final String categoria;
  final String icono;
  final bool esDorada;
  final String fecha;
}

class DisciplinaModel {
  DisciplinaModel({
    required this.clave,
    required this.nombre,
    required this.icono,
    required this.coach,
  });

  factory DisciplinaModel.fromJson(Map<String, dynamic> json) {
    return DisciplinaModel(
      clave: json['clave'] ?? 'bienestar',
      nombre: json['nombre'] ?? 'Bienestar General',
      icono: json['icono'] ?? '🌱',
      coach: json['coach'] ?? 'Coach Salihub',
    );
  }

  final String clave;
  final String nombre;
  final String icono;
  final String coach;
}

class PerfilModel {
  PerfilModel({
    required this.nombre,
    required this.enfoque,
    required this.disciplina,
  });

  factory PerfilModel.fromJson(Map<String, dynamic> json) {
    return PerfilModel(
      nombre: json['nombre'] ?? 'Persona demo',
      enfoque: json['enfoque'] ?? 'Bienestar general',
      disciplina: json['disciplina'] ?? 'bienestar',
    );
  }

  final String nombre;
  final String enfoque;
  final String disciplina;
}
