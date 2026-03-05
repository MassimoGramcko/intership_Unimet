import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// =========================================================
//  🤖  Pantalla del Asistente AI de Pasantías (Gemini)
//  Diseño premium, sin almacenamiento de historial.
// =========================================================

class AiChatbotScreen extends StatefulWidget {
  /// 'coordinator' o 'student'
  final String userRole;
  final String userName;

  const AiChatbotScreen({
    super.key,
    required this.userRole,
    required this.userName,
  });

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  // --- GEMINI ---
  static const String _apiKey = 'AIzaSyATr3dV6DqCjJeJSvnXxr6BJT96r-YBHmk';
  late final GenerativeModel _model;
  late final ChatSession _chat;

  // --- UI ---
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  // --- COLORES DEL PROYECTO ---
  static const Color _bgDark = Color(0xFF0F172A);
  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _primaryOrange = Color(0xFFFF6F00);
  static const Color _white10 = Color(0x1AFFFFFF);
  static const Color _white30 = Color(0x4DFFFFFF);
  static const Color _white60 = Color(0x99FFFFFF);

  // ----- SISTEMA DE PROMPT SEGÚN ROL -----
  String get _systemPrompt {
    if (widget.userRole == 'coordinator') {
      return '''
Eres UniBot, el asistente inteligente de gestión de pasantías de UNIMET.
Ayudas a coordinadores con:
- Gestión y revisión de solicitudes de pasantías
- Creación y administración de ofertas laborales  
- Análisis de perfiles de candidatos y recomendaciones
- Estadísticas y reportes del programa
- Procesos y reglamentos de pasantías UNIMET
- Comunicación efectiva con empresas y estudiantes

Responde siempre en español, con tono profesional pero amigable.
Usa emojis relevantes al inicio de tus respuestas para hacerlas más visuales.
Sé conciso y práctico. Si no sabes algo sobre el sistema específico de UNIMET, indícalo y sugiere contactar al departamento correspondiente.
      ''';
    } else {
      return '''
Eres UniBot, tu asistente personal de pasantías en UNIMET 🎓.
Ayudas a estudiantes con:
- Búsqueda y filtrado de ofertas de pasantías
- Cómo mejorar su perfil y CV para destacar
- Proceso de postulación y seguimiento de solicitudes
- Consejos para entrevistas y presentaciones
- Reglamentos y requisitos del programa de pasantías UNIMET
- Qué esperar durante y después de una pasantía
- Orientación profesional y carreras relacionadas

Responde en español, con tono cercano, motivador y claro.
Usa emojis para hacer las respuestas más amigables y fáciles de leer.
Sé empático con las preguntas del estudiante y anímalo a explorar oportunidades.
Si el estudiante pregunta algo muy específico del sistema interno, sugiere contactar directamente al coordinador.
      ''';
    }
  }

  List<String> get _quickSuggestions {
    if (widget.userRole == 'coordinator') {
      return [
        '📋 ¿Cómo revisar solicitudes pendientes?',
        '📊 Resumen del programa de pasantías',
        '✅ Criterios para aceptar un candidato',
        '📝 Cómo crear una buena oferta laboral',
      ];
    } else {
      return [
        '🎯 ¿Cómo mejorar mi CV?',
        '📬 ¿Cómo postularme a una oferta?',
        '🤔 ¿Qué empresas buscan mi perfil?',
        '🎤 Tips para la entrevista',
      ];
    }
  }

  @override
  void initState() {
    super.initState();

    // Inicializar Gemini con instrucción de sistema
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPrompt),
    );
    _chat = _model.startChat();

    // Mensaje de bienvenida automático
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final greeting = widget.userRole == 'coordinator'
        ? '¡Hola, ${widget.userName}! 👋\n\nSoy **UniBot**, tu asistente inteligente de gestión de pasantías. 🤖✨\n\nEstoy aquí para ayudarte a gestionar solicitudes, crear ofertas y optimizar el programa de pasantías de UNIMET.\n\n¿En qué puedo ayudarte hoy?'
        : '¡Hola, ${widget.userName}! 👋\n\nSoy **UniBot**, tu asistente personal de pasantías. 🎓✨\n\nEstoy aquí para ayudarte a encontrar la pasantía perfecta, mejorar tu perfil y guiarte en cada paso del proceso.\n\n¿Qué necesitas hoy?';

    setState(() {
      _messages.add(
        _ChatMessage(text: greeting, isUser: false, timestamp: DateTime.now()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(
        _ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      final aiText =
          response.text ?? '⚠️ No se recibió respuesta. Intenta de nuevo.';

      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: aiText,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text:
                  '❌ Error al conectar con el asistente. Verifica tu conexión e inténtalo de nuevo.',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🗑️ Limpiar chat',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Se borrará toda la conversación actual. El historial no se almacena.',
          style: TextStyle(color: _white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: _white60)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                // Reiniciar la sesión de chat
              });
              _addWelcomeMessage();
            },
            child: const Text(
              'Limpiar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCoordinator = widget.userRole == 'coordinator';
    final accentColor = isCoordinator ? Colors.blueAccent : _primaryOrange;
    final gradientColors = isCoordinator
        ? [const Color(0xFF1A237E), const Color(0xFF283593)]
        : [const Color(0xFF7F3300), const Color(0xFF9E4400)];

    return Scaffold(
      backgroundColor: _bgDark,
      body: Column(
        children: [
          // ---- HEADER PREMIUM ----
          _buildHeader(accentColor, gradientColors, isCoordinator),

          // ---- ÁREA DE MENSAJES ----
          Expanded(
            child: _messages.length <= 1 && !_isLoading
                ? _buildEmptyState(accentColor)
                : _buildMessageList(accentColor),
          ),

          // ---- SUGERENCIAS (solo si hay pocos mensajes) ----
          if (_messages.length <= 1 && !_isLoading)
            _buildQuickSuggestions(accentColor),

          // ---- INPUT AREA ----
          _buildInputArea(accentColor),
        ],
      ),
    );
  }

  // =========================================================
  //  HEADER
  // =========================================================
  Widget _buildHeader(
    Color accent,
    List<Color> gradientColors,
    bool isCoordinator,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              // Logo AI
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const _AiLogoWidget(),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UniBot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.shade400,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.6,
                                ),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isLoading
                              ? 'Escribiendo...'
                              : 'En línea · Gemini AI',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón limpiar chat
              IconButton(
                onPressed: _clearChat,
                tooltip: 'Limpiar conversación',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white70,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  //  ESTADO VACÍO (pantalla de bienvenida con el primer msg)
  // =========================================================
  Widget _buildEmptyState(Color accent) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      children: _messages
          .map((m) => _MessageBubble(message: m, accentColor: accent))
          .toList(),
    );
  }

  // =========================================================
  //  LISTA DE MENSAJES
  // =========================================================
  Widget _buildMessageList(Color accent) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _messages.length) {
          return _TypingIndicator(accentColor: accent);
        }
        return _MessageBubble(message: _messages[i], accentColor: accent);
      },
    );
  }

  // =========================================================
  //  SUGERENCIAS RÁPIDAS
  // =========================================================
  Widget _buildQuickSuggestions(Color accent) {
    return Container(
      color: _bgDark,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sugerencias',
            style: TextStyle(color: _white30, fontSize: 11, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickSuggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _sendMessage(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          color: accent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // =========================================================
  //  ÁREA DE INPUT
  // =========================================================
  Widget _buildInputArea(Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0
            ? 14
            : 14 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _bgDark,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _white10),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                onSubmitted: _isLoading ? null : _sendMessage,
                decoration: InputDecoration(
                  hintText: _isLoading
                      ? 'UniBot está respondiendo...'
                      : 'Escribe tu pregunta...',
                  hintStyle: const TextStyle(color: _white30, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Botón de enviar
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(_controller.text),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey.shade700 : accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
//  LOGO DE IA — Icono personalizado tipo "AI moderno"
// =========================================================
class _AiLogoWidget extends StatelessWidget {
  const _AiLogoWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(46, 46), painter: _AiLogoPainter());
  }
}

class _AiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double r = size.width * 0.28;

    // Pincel principal blanco brillante
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Círculo exterior
    canvas.drawCircle(center, r * 1.2, paint);

    // 6 nodos en estrella hexagonal
    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      final x = center.dx + r * 1.2 * math.cos(angle);
      final y = center.dy + r * 1.2 * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5, nodePaint);
    }

    // Líneas internas (red neuronal simplificada)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Triángulo interno
    for (int i = 0; i < 3; i++) {
      final angle1 = (i * 120 - 90) * math.pi / 180;
      final angle2 = ((i + 1) * 120 - 90) * math.pi / 180;
      canvas.drawLine(
        Offset(
          center.dx + r * 0.65 * math.cos(angle1),
          center.dy + r * 0.65 * math.sin(angle1),
        ),
        Offset(
          center.dx + r * 0.65 * math.cos(angle2),
          center.dy + r * 0.65 * math.sin(angle2),
        ),
        linePaint,
      );
    }

    // Punto central
    canvas.drawCircle(center, 3.5, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================
//  BURBUJA DE MENSAJE
// =========================================================
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final Color accentColor;

  const _MessageBubble({required this.message, required this.accentColor});

  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _white60 = Color(0x99FFFFFF);
  static const Color _black15 = Color(0x26000000);

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Avatar AI
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.8),
                    accentColor.withValues(alpha: 0.4),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const _AiLogoWidget(),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? LinearGradient(
                            colors: [
                              accentColor,
                              accentColor.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF243044), _surfaceDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? accentColor.withValues(alpha: 0.25)
                            : _black15,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildMessageText(message.text),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(color: _white60, fontSize: 10),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Renderiza el texto con soporte básico para **negrita**
  Widget _buildMessageText(String text) {
    final parts = text.split('**');
    if (parts.length <= 1) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          height: 1.5,
        ),
      );
    }
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            height: 1.5,
            fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// =========================================================
//  INDICADOR "ESCRIBIENDO..." (estático, sin animación)
// =========================================================
class _TypingIndicator extends StatelessWidget {
  final Color accentColor;

  const _TypingIndicator({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.8),
                  accentColor.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: const _AiLogoWidget(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF243044),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.7),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
//  MODELO DE MENSAJE
// =========================================================
class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
