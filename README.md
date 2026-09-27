# Reto SaliHub · DevFest Quito 2026

**¿Qué haría usted para que una persona abra SaliHub hoy y vuelva a abrirla mañana?**

Piense en alguien que no eligió instalar la app: se la pidió su empresa o se la recomendó alguien, y
nada le obliga a volver. Este repositorio es una demo de SaliHub para que no empiece de cero: un API y
una app móvil que ya funcionan. Su trabajo es mejorarla o agregarle lo que usted crea que hace volver a
la persona.

Premio: **hasta 2 pasantías pagadas** (3 meses).
Cierre: **lunes 28 de septiembre de 2026, 23:59 (hora de Ecuador).**


---

## Qué trae

| Parte | Tecnología | Qué hace |
|---|---|---|
| `api/` | Python · Django · Django REST Framework · SQLite | Check-in de la mañana, Readiness Index de 0 a 100, sesión del día ajustada al índice, registro de sesiones terminadas |
| `mobile/` | Flutter | Inicio con el índice y la sesión del día, check-in, sesión guiada con temporizador, «¿Cómo le fue?» e historial |

Hay **una sola persona de ejemplo** y no hay inicio de sesión. Al cargar los datos quedan dos semanas de
historial inventado, y el día de hoy queda libre para que usted haga el check-in.

### Cómo funciona

1. **Check-in de la mañana:** 6 preguntas (energía, cuerpo, horas y calidad de sueño, actividad y tiempo
   sentado de ayer). Uno por día.
2. **Readiness Index:** un número de 0 a 100 que dice cómo llega la persona hoy, con 5 niveles:
   Disposición óptima, Buena disposición, Disposición moderada, Fatiga / desbalance y Alerta.
3. **Sesión del día:** cada nivel tiene un esfuerzo máximo (escala de 0 a 10), y la app recomienda una
   sesión que no lo pase.
4. **Sesión guiada:** pasos con temporizador y, al final, «¿Cómo le fue?»: estrellas y esfuerzo percibido.

---

## Cómo participar

1. **Descargue SaliHub** (App Store o Google Play), cree su cuenta y haga su primer Readiness Index.
   Úsela: la demo se inspira en ella, y el reto es sobre la persona que la usa.
2. **Cree su copia de este repositorio** con el botón **«Use this template»** de GitHub. Déjela pública.
   Hágalo al empezar: revisamos su historial de commits desde el primero.
3. **Llene el formulario** de la competencia con su hoja de vida y el enlace de su repositorio.
4. **Trabaje en su copia y haga commits a medida que avanza.** No suba todo al final.
5. **Explique su decisión** en la sección «Mi propuesta» al final de este README.

### Dónde ponerse creativo

Puede tocar el API, la app o las dos. Algunas preguntas para arrancar. No son obligatorias, y la mejor
idea puede no estar aquí:

- La app no tiene rachas ni metas. ¿Algo así haría volver a alguien, o lo cansaría?
- ¿Qué le diría la app a alguien que lleva tres días sin abrirla?
- ¿Qué le gustaría ver al día siguiente de una sesión dura, o de una mala noche?
- ¿El check-in de 6 preguntas es demasiado largo para todos los días?
- ¿La recomendación explica por qué? ¿Debería hacerlo?
- La fórmula del índice es un promedio simple. ¿Cambiaría cómo se calcula o cómo se muestra?

Para probar «volver mañana», el botón de calendario de la app simula el día siguiente. En el API,
agregue `?fecha=AAAA-MM-DD` a cualquier ruta.

---

## Cómo correrlo

Necesita Python 3.11 o más reciente y Flutter 3.35 o más reciente.

### API

```bash
cd api
python3 -m venv .venv
source .venv/bin/activate          # En Windows: .venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py sembrar           # carga las sesiones y el historial de ejemplo
python manage.py runserver
```

El API queda en `http://localhost:8000/api/`. Pruebas: `python manage.py test demo`.

### App móvil

Con el API corriendo, en otra terminal:

```bash
cd mobile
flutter pub get
flutter run -d chrome                                               # en el navegador, lo más rápido
flutter run --dart-define=API_URL=http://10.0.2.2:8000              # emulador de Android
```

En el simulador de iOS, `localhost` funciona tal cual. En un teléfono físico, use la IP de su computadora
en la red (`--dart-define=API_URL=http://192.168.x.x:8000`) y corra el API con
`python manage.py runserver 0.0.0.0:8000`.

Revisión y pruebas: `flutter analyze` y `flutter test`.

### Rutas del API

| Método | Ruta | Qué hace |
|---|---|---|
| GET | `/api/perfil/` | La persona de ejemplo |
| GET | `/api/checkin/preguntas/` | Las 6 preguntas con sus opciones |
| POST | `/api/checkin/` | Guarda el check-in de hoy. Cuerpo: `{"respuestas": {"energia": 3, ...}}`, con el número de la opción elegida (desde 0) |
| GET | `/api/indice/hoy/` | El índice de hoy, o `hecho: false` si falta el check-in |
| GET | `/api/indice/historial/?dias=14` | El índice de los últimos días |
| GET | `/api/entrenamiento/sesion-del-dia/` | La sesión recomendada según el índice de hoy |
| GET | `/api/entrenamiento/sesiones/` | Todas las sesiones |
| GET | `/api/entrenamiento/sesiones/<codigo>/` | Una sesión con sus pasos |
| GET / POST | `/api/entrenamiento/registros/` | Sesiones terminadas. Cuerpo: `{"sesion": "movilidad-matutina", "valoracion": 1-5, "esfuerzo": 0-10, "comentario": ""}` |

El contenido fijo (preguntas, niveles y sesiones) está en `api/demo/catalogo.py`, y la fórmula del índice
en `api/demo/indice.py`.

---

## Qué evaluamos

| Qué miramos | Qué quiere decir |
|---|---|
| Entendió al usuario | Piensa en alguien que no eligió instalar la app, no en un usuario genérico |
| Funciona | Lo que construyó corre. Importa que funcione, no que se vea bonito |
| Cómo lo construyó | El historial de commits: si avanzó con orden o subió todo el último día |
| El código se puede leer | Nombres, estructura y un README que explique la decisión |

## Reglas

- La participación es individual.
- Use solo datos inventados. No suba datos personales reales, ni suyos ni de otras personas.
- Puede usar herramientas de IA. En la entrevista le pediremos que explique en vivo las decisiones de su
  código.
- Su código es suyo. SaliHub no lo publica ni lo usa sin su permiso escrito.
- Cuenta el último commit hasta el lunes 28 de septiembre a las 23:59 (hora de Ecuador).

## Fechas

| Hito | Fecha |
|---|---|
| Apertura | Sábado 26 de septiembre, en el stand de SaliHub del DevFest |
| Cierre | Lunes 28 de septiembre, 23:59 (hora de Ecuador) |
| Revisión de repositorios | Martes 29 de septiembre a jueves 1 de octubre |
| Entrevistas | Semana del 5 de octubre |
| Anuncio de ganadores | Viernes 9 de octubre, por correo |

---

## Mi propuesta: "Swipe & Collect — Cartas de Rendimiento Diario"

- **Qué problema vi al usar la app:** El check-in tradicional de 6 preguntas es técnicamente correcto pero emocionalmente plano. Se percibe como un formulario médico estático: nada distingue la experiencia del día 1 de la del día 30, y no existe una motivación intrínseca para reingresar al día siguiente. Para un usuario deportista o corporativo que no eligió instalar la app voluntariamente, la fricción de "responder 6 preguntas repetitivas" genera abandono en la primera semana.

- **Qué construí y por qué creo que hace volver a la persona:**
  1. **Check-in por Swipe Adaptativo:** Reemplacé el formulario por una mazo táctil de cartas donde el usuario desliza a la derecha (OK / Fresco) o izquierda (Fatiga / Alerta). Las preguntas se adaptan dinámicamente al tono y jerga de su disciplina deportiva (*Runner, Ciclista, CrossFitter o Bienestar General*).
  2. **Sistema de Cartas Coleccionables Diarias (Gamificación Empática):** Al completar el check-in, el usuario desbloquea una **Carta Coleccionable del Día** con un insight técnico y frase motivacional adaptados a su disciplina y a su nivel de Readiness Index.
  3. **Reconocimiento por Logros ("Carta Dorada"):** Si el índice del día supera el máximo de los últimos 30 días, la carta se transforma en una **Carta Dorada Épica**, premiando el rendimiento real sin usar rachas tóxicas ni penalizaciones por ausencias.
  4. **Álbum Digital ("Mi Colección"):** Un mazo coleccionable interactivo donde el deportista revisa su historial de insights, fomentando la curiosidad diaria (*"¿Qué carta desbloquearé mañana?"*).

- **Qué cambié en el API y qué en la app:**
  - **API (Django/DRF):**
    - `catalogo.py`: Creación del catálogo multidisciplina de preguntas con jerga deportiva y más de 30 Cartas Coleccionables clasificadas por nivel (`optima`, `buena`, `moderada`, `fatiga`, `alerta`) y categoría (*Nutrición, Biomecánica, Mentalidad, Recuperación*).
    - `models.py` & `views.py`: Endpoint `GET/PUT /api/perfil/` con soporte para actualizar la disciplina del deportista (`runner`, `ciclista`, `crossfitter`, `bienestar`), y nuevo endpoint `GET /api/cartas/` para consultar el álbum de cartas desbloqueadas.
    - `indice.py`: Implementación de `elegir_carta()` determinística basada en la fecha y nivel, y algoritmo de detección de **Carta Dorada** comparando dinámicamente el récord histórico de 30 días.
  - **App Móvil (Flutter):**
    - `pantallas/checkin.dart`: Rediseño completo a interfaz táctil por Swipe usando gestos nativos (`GestureDetector`, `Transform`, `AnimationController`).
    - `pantallas/carta_revelada.dart`: Pantalla de animación de volteo 3D (Flip Card) al completar el check-in con efectos visuales para Cartas Doradas.
    - `pantallas/coleccion.dart`: Vista de Álbum Digital en grilla con filtros por disciplina y detalle modal de cada carta.
    - `modelos.dart`: Estructuras de datos strongly typed (`CartaModel`, `PerfilModel`).

- **Principios SOLID y Clean Architecture Aplicados:**
  - **Single Responsibility Principle (SRP):** Separación estricta entre definición de catálogo (`catalogo.py`), reglas del dominio (`indice.py`), persistencia de datos (`models.py`) y controladores HTTP (`views.py`).
  - **Open/Closed Principle (OCP):** El sistema de cartas y disciplinas se extiende mediante configuración de objetos en `catalogo.py` sin modificar los algoritmos centrales de cálculo en `indice.py`.
  - **Liskov Substitution & Interface Segregation (LSP / ISP):** Respuestas de endpoints estandarizadas a través de serializadores desacoplados en DRF y modelos en Flutter.
  - **Dependency Inversion (DIP):** El cliente de API en Flutter (`api.dart`) expone una abstracción limpia consumida independientemente por las pantallas UI.

- **Qué haría con más tiempo:** Implementar haptics/vibración táctil al deslizar cartas en dispositivos físicos, audio sutil al revelar cartas doradas y exportación de cartas en formato imagen para compartir logros en Instagram/Strava.