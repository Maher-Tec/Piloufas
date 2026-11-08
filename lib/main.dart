import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF06070B),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const DecisionApp());
}

// ---------------------------------------------------------------------------
// THEME & ROYAL PALETTE DEFINITIONS
// ---------------------------------------------------------------------------
class AuraPalette {
  final String id;
  final String name;
  final String subtitle;
  final Color bgTop;
  final Color bgBottom;
  final Color panel;
  final Color primaryGold;
  final Color secondaryGold;
  final Color champagne;
  final Color headsColor;
  final Color tailsColor;
  final Color glowColor;

  const AuraPalette({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.bgTop,
    required this.bgBottom,
    required this.panel,
    required this.primaryGold,
    required this.secondaryGold,
    required this.champagne,
    required this.headsColor,
    required this.tailsColor,
    required this.glowColor,
  });

  static const List<AuraPalette> presets = [
    AuraPalette(
      id: 'sovereign',
      name: 'Sovereign Gold',
      subtitle: 'Imperial obsidian & warm 24k gold',
      bgTop: Color(0xFF0E1018),
      bgBottom: Color(0xFF050609),
      panel: Color(0xFF151824),
      primaryGold: Color(0xFFFFD470),
      secondaryGold: Color(0xFFD4922A),
      champagne: Color(0xFFFFF3D6),
      headsColor: Color(0xFFFFC857),
      tailsColor: Color(0xFF56CFE1),
      glowColor: Color(0xFFFFB732),
    ),
    AuraPalette(
      id: 'emerald',
      name: 'Imperial Jade',
      subtitle: 'Deep emerald vault & burnished gold',
      bgTop: Color(0xFF081715),
      bgBottom: Color(0xFF040908),
      panel: Color(0xFF0F221F),
      primaryGold: Color(0xFFFFD875),
      secondaryGold: Color(0xFFC88A28),
      champagne: Color(0xFFFFF5DC),
      headsColor: Color(0xFFFFCF5C),
      tailsColor: Color(0xFF38EF7D),
      glowColor: Color(0xFF2EC4B6),
    ),
    AuraPalette(
      id: 'dynasty',
      name: 'Crimson Velvet',
      subtitle: 'Royal opera crimson & champagne',
      bgTop: Color(0xFF1B0B12),
      bgBottom: Color(0xFF080406),
      panel: Color(0xFF241119),
      primaryGold: Color(0xFFFFD573),
      secondaryGold: Color(0xFFD98A2B),
      champagne: Color(0xFFFFF0D4),
      headsColor: Color(0xFFFFC95E),
      tailsColor: Color(0xFFFF6B8B),
      glowColor: Color(0xFFE63946),
    ),
    AuraPalette(
      id: 'celestial',
      name: 'Astral Sapphire',
      subtitle: 'Midnight cosmos & starlight gold',
      bgTop: Color(0xFF0B1026),
      bgBottom: Color(0xFF050711),
      panel: Color(0xFF131A38),
      primaryGold: Color(0xFFFFD670),
      secondaryGold: Color(0xFFCF8E28),
      champagne: Color(0xFFFFF4DA),
      headsColor: Color(0xFFFFCA58),
      tailsColor: Color(0xFF9B72FF),
      glowColor: Color(0xFF6C63FF),
    ),
  ];
}

class DecisionApp extends StatelessWidget {
  const DecisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Piloufas · Maher Ahmed',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050609),
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD470),
          brightness: Brightness.dark,
        ),
      ),
      home: const CoinHome(),
    );
  }
}

// ---------------------------------------------------------------------------
// MAIN STATEFUL EXPERIENCE
// ---------------------------------------------------------------------------
class CoinHome extends StatefulWidget {
  const CoinHome({super.key});

  @override
  State<CoinHome> createState() => _CoinHomeState();
}

class _CoinHomeState extends State<CoinHome> with TickerProviderStateMixin {
  final TextEditingController a = TextEditingController();
  final TextEditingController b = TextEditingController();
  final FocusNode focusA = FocusNode();
  final FocusNode focusB = FocusNode();

  late final AnimationController spin;
  late final AnimationController ambient;
  late final AnimationController burst;
  late final AnimationController swapAnim;
  late final AnimationController shakeAnim;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  Offset sensorTilt = Offset.zero;

  final AudioPlayer player = AudioPlayer();
  final AudioPlayer tickPlayer = AudioPlayer();
  final math.Random rng = math.Random.secure();
  late final Future<List<ui.Image>> _coinTextures = _loadCoinTextures();

  List<Map<String, dynamic>> records = [];
  int tab = 0;
  int phase = 0; // 0 = setup, 1 = airborne, 2 = revealed
  int winner = 0; // 0 = Heads (A), 1 = Tails (B)
  bool muted = false;
  bool reduceMotion = false;
  bool hapticsEnabled = true;
  bool blindReveal = false;
  bool isRevealed = true;
  bool ready = false;
  String? hoped;
  String auraId = 'sovereign';
  String historyFilter = 'all';

  // Interactive 3D coin inspection state on home/result stage
  bool previewHeads = true;
  Offset userTilt = Offset.zero;
  double dragStartY = 0;
  int _lastHalfTurn = -1;

  static const List<Map<String, String>> presets = [
    {'label': '✨ Work vs Rest', 'a': 'Deep work session', 'b': 'Guilt-free rest'},
    {'label': '🚀 Ship vs Polish', 'a': 'Launch it today', 'b': 'Refine one more day'},
    {'label': '🏋️ Gym vs Recovery', 'a': 'Hit the workout', 'b': 'Stretch & recover'},
    {'label': '🍽️ Cook vs Order', 'a': 'Cook at home', 'b': 'Order gourmet takeout'},
    {'label': '🎲 Bold Risk vs Safe', 'a': 'Take the bold leap', 'b': 'Play the steady hand'},
    {'label': '🌅 Early vs Night Owl', 'a': 'Sleep now, rise early', 'b': 'Ride the night flow'},
  ];

  AuraPalette get palette => AuraPalette.presets.firstWhere(
        (p) => p.id == auraId,
        orElse: () => AuraPalette.presets.first,
      );

  @override
  void initState() {
    super.initState();
    a.text = 'Execute the bold vision';
    b.text = 'Step back & recharge';

    spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4100),
    )..addListener(_onSpinTick);

    ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    shakeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    swapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    try {
      _accelSub = accelerometerEventStream().listen((event) {
        if (!mounted) return;
        final targetX = (-event.x / 9.8).clamp(-0.45, 0.45);
        final targetY = ((event.y - 6.0) / 9.8).clamp(-0.35, 0.35);
        setState(() {
          sensorTilt = Offset(
            sensorTilt.dx * 0.85 + targetX * 0.15,
            sensorTilt.dy * 0.85 + targetY * 0.15,
          );
        });
      });
    } catch (_) {}

    spin.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          phase = 2;
          isRevealed = !blindReveal;
        });
        shakeAnim.forward(from: 0);
        burst.forward(from: 0);
        _sound('metal_land');
        Future.delayed(const Duration(milliseconds: 220), () {
          if (mounted && isRevealed) _sound('reveal');
        });
        _hapticHeavy();

        records.insert(0, {
          'a': a.text.trim(),
          'b': b.text.trim(),
          'winner': winner,
          'hoped': winner == 0 ? 'A' : 'B',
          'date': DateTime.now().toIso8601String(),
        });
        _save();
      }
    });

    focusA.addListener(() => setState(() {}));
    focusB.addListener(() => setState(() {}));
    _load();
  }

  void _onSpinTick() {
    if (phase != 1) return;
    final t = spin.value;
    if (t < 0.78) {
      final eased = Curves.easeInOutCubic.transform((t / 0.78).clamp(0.0, 1.0));
      final totalAngle = (math.pi * 10 + (winner == 0 ? 0 : math.pi)) * eased;
      final halfTurn = (totalAngle / math.pi).floor();
      if (halfTurn != _lastHalfTurn && halfTurn > 0 && halfTurn <= 10) {
        _lastHalfTurn = halfTurn;
        if (halfTurn % 2 == 0) {
          _tickSound();
        }
        if (hapticsEnabled) {
          HapticFeedback.selectionClick();
        }
      }
    }
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('decisions');
    if (raw != null) {
      try {
        records = (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {}
    }
    muted = p.getBool('mute') ?? false;
    reduceMotion = p.getBool('reduce_motion') ?? false;
    hapticsEnabled = p.getBool('haptics') ?? true;
    blindReveal = p.getBool('blind_reveal') ?? false;
    auraId = p.getString('aura_id') ?? 'sovereign';
    if (mounted) setState(() => ready = true);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('decisions', jsonEncode(records));
    await p.setBool('mute', muted);
    await p.setBool('reduce_motion', reduceMotion);
    await p.setBool('haptics', hapticsEnabled);
    await p.setBool('blind_reveal', blindReveal);
    await p.setString('aura_id', auraId);
  }

  Future<void> _sound(String name) async {
    if (muted) return;
    try {
      await player.stop();
      await player.play(AssetSource('audio/$name.wav'), volume: 0.72);
    } catch (e) {
      debugPrint('Audio: $e');
    }
  }

  Future<void> _tickSound() async {
    if (muted || reduceMotion) return;
    try {
      await tickPlayer.stop();
      await tickPlayer.play(AssetSource('audio/metal_tick.wav'), volume: 0.28);
    } catch (_) {}
  }

  void _hapticLight() {
    if (hapticsEnabled) HapticFeedback.lightImpact();
  }

  void _hapticMedium() {
    if (hapticsEnabled) HapticFeedback.mediumImpact();
  }

  void _hapticHeavy() {
    if (hapticsEnabled) HapticFeedback.heavyImpact();
  }

  void _flip({double velocity = 0}) {
    if (a.text.trim().isEmpty || b.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: palette.panel,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: palette.primaryGold.withValues(alpha: 0.5)),
          ),
          content: Row(
            children: [
              Icon(Icons.auto_awesome, color: palette.primaryGold, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Inscribe both Heads and Tails choices before tossing the coin.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    winner = rng.nextBool() ? 0 : 1;
    hoped = null;
    userTilt = Offset.zero;
    _lastHalfTurn = -1;
    isRevealed = !blindReveal;

    final baseDuration = reduceMotion ? 950 : 4100;
    final extra = (velocity > 280)
        ? ((velocity - 280) / 7.5).clamp(0, 1500).toInt()
        : 0;
    spin.duration = Duration(milliseconds: reduceMotion ? 950 : baseDuration + extra);

    spin.reset();
    burst.reset();
    shakeAnim.reset();
    setState(() => phase = 1);
    _sound('air_whoosh');
    _hapticMedium();
    spin.forward();
  }

  void _catchCoinMidAir() {
    if (phase != 1) return;
    spin.stop();
    setState(() {
      phase = 2;
      isRevealed = !blindReveal;
    });
    shakeAnim.forward(from: 0);
    burst.forward(from: 0);
    _sound('metal_land');
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted && isRevealed) _sound('reveal');
    });
    _hapticHeavy();

    records.insert(0, {
      'a': a.text.trim(),
      'b': b.text.trim(),
      'winner': winner,
      'hoped': winner == 0 ? 'A' : 'B',
      'date': DateTime.now().toIso8601String(),
    });
    _save();
  }

  void _reset() {
    setState(() {
      phase = 0;
      hoped = null;
      userTilt = Offset.zero;
      isRevealed = true;
    });
    spin.reset();
    burst.reset();
    shakeAnim.reset();
    _sound('tap');
  }

  void _showRoyalDecreeDialog() {
    final isHeads = winner == 0;
    final winText = isHeads ? a.text : b.text;
    final winSide = isHeads ? 'HEADS' : 'TAILS';
    final winColor = isHeads ? palette.headsColor : palette.tailsColor;
    final decreeId = 'SA-${rng.nextInt(899999) + 100000}';
    final dateStr = DateTime.now().toLocal().toString().split('.')[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: BoxDecoration(
            color: const Color(0xFF0C0E17).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: palette.primaryGold.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: palette.primaryGold.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.primaryGold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: palette.primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'OFFICIAL ROYAL DECREE',
                    style: TextStyle(
                      color: palette.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.workspace_premium_rounded, color: palette.primaryGold, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Piloufas · Sovereign Edition by Maher Ahmed',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: palette.primaryGold.withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    isHeads ? 'assets/images/coin_heads.png' : 'assets/images/coin_tails.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: winColor.withValues(alpha: 0.16),
                  border: Border.all(color: winColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  '$winSide PREVAILS',
                  style: TextStyle(
                    color: winColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '“$winText”',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'By the immutable toss of the Sovereign Coin, this path is sealed by fate. Follow through with unwavering certainty.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: palette.primaryGold.withValues(alpha: 0.2)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DECREE: #$decreeId',
                      style: TextStyle(fontSize: 11, color: palette.champagne.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
                  Text(dateStr,
                      style: const TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: '👑 Piloufas · Royal Decree of Maher Ahmed: The coin selected "$winText" ($winSide) on $dateStr. Destiny sealed!',
                        ));
                        _sound('tap');
                        _hapticLight();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: palette.panel,
                            content: Text('Decree copied to clipboard ✨', style: TextStyle(color: palette.champagne)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Decree'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.champagne,
                        side: BorderSide(color: palette.primaryGold.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primaryGold,
                        foregroundColor: const Color(0xFF140E02),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _swapChoices() {
    swapAnim.forward(from: 0);
    final temp = a.text;
    setState(() {
      a.text = b.text;
      b.text = temp;
      previewHeads = !previewHeads;
    });
    _sound('tap');
    _hapticLight();
  }

  Future<List<ui.Image>> _loadCoinTextures() async {
    final result = <ui.Image>[];
    for (final name in ['heads', 'tails']) {
      final bytes = await rootBundle.load('assets/images/coin_$name.png');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      result.add((await codec.getNextFrame()).image);
    }
    return result;
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    a.dispose();
    b.dispose();
    focusA.dispose();
    focusB.dispose();
    spin.dispose();
    ambient.dispose();
    burst.dispose();
    swapAnim.dispose();
    shakeAnim.dispose();
    player.dispose();
    tickPlayer.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // SHARED LUXURY UI COMPONENTS
  // -------------------------------------------------------------------------
  Widget luxuryGlass({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
    Color? borderAccent,
    double borderRadius = 26,
    bool elevated = true,
  }) {
    final accent = borderAccent ?? palette.primaryGold;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.panel.withValues(alpha: 0.92),
            Color.lerp(palette.panel, Colors.black, 0.45)!.withValues(alpha: 0.94),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 32,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  Widget sectionHeading(String eyebrow, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: palette.primaryGold.withValues(alpha: 0.1),
            border: Border.all(color: palette.primaryGold.withValues(alpha: 0.3)),
          ),
          child: Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              color: palette.primaryGold,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white,
              palette.champagne,
              palette.primaryGold,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1.15,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.64),
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget royalGoldButton({
    required String label,
    required VoidCallback onPressed,
    String? subtitle,
    IconData icon = Icons.toll_rounded,
  }) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, _) {
        final shimmerPos = (ambient.value * 2.5) % 1.0;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + shimmerPos * 2.4, -0.8),
              end: Alignment(-0.2 + shimmerPos * 2.4, 0.8),
              colors: [
                palette.secondaryGold,
                palette.primaryGold,
                palette.champagne,
                palette.primaryGold,
                palette.secondaryGold,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primaryGold.withValues(alpha: 0.38),
                blurRadius: 26,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: palette.primaryGold.withValues(alpha: 0.18),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.16),
                      ),
                      child: Icon(icon, color: const Color(0xFF1A1204), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Color(0xFF140E02),
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: const Color(0xFF140E02).withValues(alpha: 0.72),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
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
      },
    );
  }

  Widget interactiveCoinStage({
    required double progress,
    required bool heads,
    required bool airborne,
    double height = 310,
    bool shrouded = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: airborne
          ? null
          : (details) {
              dragStartY = details.localPosition.dy;
            },
      onPanUpdate: airborne
          ? null
          : (details) {
              setState(() {
                final dx = (userTilt.dx + details.delta.dx * 0.006).clamp(-0.55, 0.55);
                final dy = (userTilt.dy + details.delta.dy * 0.006).clamp(-0.35, 0.35);
                userTilt = Offset(dx, dy);
              });
            },
      onPanEnd: airborne
          ? null
          : (details) {
              final velocityY = details.velocity.pixelsPerSecond.dy;
              if (velocityY < -220 && phase == 0) {
                _flip(velocity: velocityY.abs());
                return;
              }
              setState(() => userTilt = Offset.zero);
            },
      onTap: airborne
          ? () {
              _catchCoinMidAir();
            }
          : () {
              if (phase == 0) {
                setState(() => previewHeads = !previewHeads);
                _sound('tap');
                _hapticLight();
              } else if (phase == 2) {
                if (shrouded) {
                  setState(() => isRevealed = true);
                  _sound('reveal');
                  _hapticHeavy();
                  burst.forward(from: 0);
                  shakeAnim.forward(from: 0);
                } else {
                  _sound('metal_tick');
                  _hapticLight();
                }
              }
            },
      child: SizedBox(
        height: height,
        width: 350,
        child: FutureBuilder<List<ui.Image>>(
          future: _coinTextures,
          builder: (context, snapshot) => AnimatedBuilder(
            animation: Listenable.merge([ambient, burst, shakeAnim]),
            builder: (context, _) => CustomPaint(
              painter: MintedCoinPainter(
                progress: progress,
                ambientProgress: ambient.value,
                burstProgress: phase == 2 ? burst.value : 0.0,
                heads: heads,
                textures: snapshot.data,
                airborne: airborne,
                winningHeads: winner == 0,
                userTilt: Offset(userTilt.dx + sensorTilt.dx, userTilt.dy + sensorTilt.dy),
                palette: palette,
                shrouded: shrouded,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 0 — PHASE 0: THE ORACLE SETUP STAGE
  // -------------------------------------------------------------------------
  Widget buildHomeStage() {
    return Column(
      children: [
        sectionHeading(
          'Piloufas · Maher Ahmed',
          'Two Paths. One Moment of Truth.',
          'Set your dilemma, toss the sovereign coin, and notice what your heart secretly hopes for mid-flight.',
        ),
        const SizedBox(height: 16),

        // Quick Dilemma Presets Bar
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = presets[index];
              final isSelected = a.text == item['a'] && b.text == item['b'];
              return ActionChip(
                onPressed: () {
                  setState(() {
                    a.text = item['a']!;
                    b.text = item['b']!;
                  });
                  _sound('tap');
                  _hapticLight();
                },
                backgroundColor: isSelected
                    ? palette.primaryGold.withValues(alpha: 0.22)
                    : palette.panel.withValues(alpha: 0.85),
                side: BorderSide(
                  color: isSelected
                      ? palette.primaryGold
                      : Colors.white.withValues(alpha: 0.12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                label: Text(
                  item['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? palette.champagne : Colors.white70,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        // Dual Luxury Input Cards with Animated Swap Medallion
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                _buildChoiceCard(
                  sideLabel: 'HEADS',
                  sideSub: 'PORTRAIT CROWN',
                  badgeLetter: 'A',
                  controller: a,
                  focusNode: focusA,
                  accent: palette.headsColor,
                  isHeads: true,
                ),
                const SizedBox(height: 12),
                _buildChoiceCard(
                  sideLabel: 'TAILS',
                  sideSub: 'ROYAL LAUREL',
                  badgeLetter: 'B',
                  controller: b,
                  focusNode: focusB,
                  accent: palette.tailsColor,
                  isHeads: false,
                ),
              ],
            ),
            Positioned(
              right: 22,
              child: RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(
                  CurvedAnimation(parent: swapAnim, curve: Curves.easeOutBack),
                ),
                child: Tooltip(
                  message: 'Swap Heads & Tails choices',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _swapChoices,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              palette.panel,
                              const Color(0xFF090B12),
                            ],
                          ),
                          border: Border.all(
                            color: palette.primaryGold.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.7),
                              blurRadius: 12,
                            ),
                            BoxShadow(
                              color: palette.primaryGold.withValues(alpha: 0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.swap_vert_rounded,
                          color: palette.primaryGold,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Interactive 3D Coin Showcase
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            interactiveCoinStage(
              progress: 0.0,
              heads: previewHeads,
              airborne: false,
              height: 285,
            ),
            Positioned(
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 13,
                      color: palette.primaryGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      previewHeads
                          ? 'Showing HEADS · Tap coin to flip face or drag to tilt'
                          : 'Showing TAILS · Tap coin to flip face or drag to tilt',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        royalGoldButton(
          label: 'Toss the Sovereign Coin',
          subtitle: 'Or flick the coin upward to launch',
          onPressed: _flip,
          icon: Icons.auto_awesome_rounded,
        ),

        const SizedBox(height: 14),
        Text(
          '“When a coin is in the air, you suddenly know what you are hoping for.”',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.48),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceCard({
    required String sideLabel,
    required String sideSub,
    required String badgeLetter,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color accent,
    required bool isHeads,
  }) {
    final isFocused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(16, 12, 58, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isFocused
                ? accent.withValues(alpha: 0.16)
                : palette.panel.withValues(alpha: 0.9),
            Color.lerp(palette.panel, Colors.black, 0.5)!,
          ],
        ),
        border: Border.all(
          color: isFocused
              ? accent.withValues(alpha: 0.85)
              : accent.withValues(alpha: 0.26),
          width: isFocused ? 1.6 : 1.1,
        ),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: accent.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => previewHeads = isHeads);
              _sound('tap');
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.35),
                    accent.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isHeads ? Icons.workspace_premium_rounded : Icons.stars_rounded,
                    color: accent,
                    size: 18,
                  ),
                  Text(
                    sideLabel,
                    style: TextStyle(
                      color: accent,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$sideLabel · $sideSub',
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.9),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLength: 90,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    counterText: '',
                    hintText: 'Enter option for $sideLabel...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 0 — PHASE 1: AIRBORNE CINEMATIC FLIGHT (EMPTY SCREEN · JUST THE COIN)
  // -------------------------------------------------------------------------
  Widget buildFlippingStage() {
    return AnimatedBuilder(
      animation: spin,
      builder: (context, _) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              interactiveCoinStage(
                progress: spin.value,
                heads: winner == 0,
                airborne: true,
                height: 440,
              ),
              const SizedBox(height: 8),
              AnimatedOpacity(
                opacity: spin.value < 0.65 ? 0.75 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.primaryGold.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, color: palette.primaryGold, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Tap mid-air to catch the coin',
                        style: TextStyle(
                          color: palette.champagne,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // TAB 0 — PHASE 2: REVEAL STAGE (MINIMALIST · JUST THE COIN & OUTCOME)
  // -------------------------------------------------------------------------
  Widget buildResultStage() {
    final isHeads = winner == 0;
    final winText = isHeads ? a.text : b.text;
    final winSide = isHeads ? 'HEADS' : 'TAILS';
    final winColor = isHeads ? palette.headsColor : palette.tailsColor;

    if (blindReveal && !isRevealed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            interactiveCoinStage(
              progress: 0.0,
              heads: isHeads,
              airborne: false,
              height: 330,
              shrouded: true,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: palette.primaryGold.withValues(alpha: 0.12),
                border: Border.all(color: palette.primaryGold.withValues(alpha: 0.4)),
              ),
              child: Text(
                'DESTINY SEALED IN SECRET',
                style: TextStyle(
                  color: palette.primaryGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Before lifting the veil… which path was your heart secretly wishing for?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: royalGoldButton(
                label: 'Lift the Veil & Reveal',
                subtitle: 'Tap here or tap the shrouded coin',
                icon: Icons.visibility_rounded,
                onPressed: () {
                  setState(() => isRevealed = true);
                  _sound('reveal');
                  _hapticHeavy();
                  burst.forward(from: 0);
                  shakeAnim.forward(from: 0);
                },
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          interactiveCoinStage(
            progress: 0.0,
            heads: isHeads,
            airborne: false,
            height: 330,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: winColor.withValues(alpha: 0.16),
              border: Border.all(color: winColor.withValues(alpha: 0.5), width: 1.2),
            ),
            child: Text(
              winSide,
              style: TextStyle(
                color: winColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              winText,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('New Dilemma'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [palette.secondaryGold, palette.primaryGold],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: palette.primaryGold.withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: () => _flip(),
                      icon: const Icon(Icons.replay_rounded, color: Color(0xFF140E02), size: 20),
                      label: const Text(
                        'Toss Again',
                        style: TextStyle(
                          color: Color(0xFF140E02),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _showRoyalDecreeDialog,
            icon: Icon(Icons.workspace_premium_rounded, color: palette.primaryGold, size: 18),
            label: Text(
              'View & Share Royal Decree',
              style: TextStyle(
                color: palette.champagne,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 1: CHRONICLE (HISTORY)
  // -------------------------------------------------------------------------
  Widget buildHistoryTab() {
    final filtered = records.where((r) {
      final winCode = r['winner'] == 0 ? 'A' : 'B';
      if (historyFilter == 'aligned') return r['hoped'] == winCode;
      if (historyFilter == 'rebelled') {
        return r['hoped'] != 'unsure' && r['hoped'] != winCode;
      }
      if (historyFilter == 'unsure') return r['hoped'] == 'unsure';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionHeading(
          'Royal Chronicle',
          'Your Decision Archive',
          'Every toss is a mirror of what mattered to you in that moment.',
        ),
        const SizedBox(height: 18),

        // Filter Chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('all', 'All (${records.length})'),
              const SizedBox(width: 8),
              _buildFilterChip('aligned', 'Aligned ✨'),
              const SizedBox(width: 8),
              _buildFilterChip('rebelled', 'Gut Rebelled 💡'),
              const SizedBox(width: 8),
              _buildFilterChip('unsure', 'Neutral ⚖️'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          luxuryGlass(
            padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
            child: Column(
              children: [
                Icon(
                  Icons.history_edu_rounded,
                  size: 48,
                  color: palette.primaryGold.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 14),
                const Text(
                  'No Recorded Decisions Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Toss the Sovereign Coin and record your gut reaction to build your personal intuition chronicle.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...filtered.map((r) {
            final originalIndex = records.indexOf(r);
            final isHeads = r['winner'] == 0;
            final winCode = isHeads ? 'A' : 'B';
            final hopedVal = r['hoped'] as String? ?? 'unsure';
            final aligned = hopedVal == winCode;
            final unsure = hopedVal == 'unsure';
            final dateStr = (r['date'] as String? ?? '').split('T').first;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: luxuryGlass(
                padding: const EdgeInsets.all(16),
                borderAccent: isHeads ? palette.headsColor : palette.tailsColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: (isHeads ? palette.headsColor : palette.tailsColor)
                                .withValues(alpha: 0.2),
                          ),
                          child: Text(
                            isHeads ? 'HEADS WON' : 'TAILS WON',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: isHeads ? palette.headsColor : palette.tailsColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                          child: Text(
                            unsure
                                ? '⚖️ Neutral'
                                : aligned
                                    ? '✨ Aligned'
                                    : '💡 Hoped for Other',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HEADS: ${r['a']}',
                                style: TextStyle(
                                  fontWeight: isHeads ? FontWeight.w800 : FontWeight.w500,
                                  color: isHeads ? Colors.white : Colors.white60,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'TAILS: ${r['b']}',
                                style: TextStyle(
                                  fontWeight: !isHeads ? FontWeight.w800 : FontWeight.w500,
                                  color: !isHeads ? Colors.white : Colors.white60,
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Load into Oracle Stage',
                          onPressed: () {
                            setState(() {
                              a.text = r['a'] as String;
                              b.text = r['b'] as String;
                              phase = 0;
                              tab = 0;
                            });
                            _sound('tap');
                          },
                          icon: Icon(Icons.replay_circle_filled_rounded,
                              color: palette.primaryGold, size: 26),
                        ),
                        IconButton(
                          tooltip: 'Remove entry',
                          onPressed: () {
                            if (originalIndex >= 0) {
                              setState(() => records.removeAt(originalIndex));
                              _save();
                              _hapticLight();
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white38, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final selected = historyFilter == id;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => historyFilter = id);
        _sound('tap');
      },
      selectedColor: palette.primaryGold.withValues(alpha: 0.25),
      backgroundColor: palette.panel,
      side: BorderSide(
        color: selected ? palette.primaryGold : Colors.white.withValues(alpha: 0.12),
      ),
      labelStyle: TextStyle(
        color: selected ? palette.champagne : Colors.white70,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 2: INTUITION ANALYTICS (INSIGHTS)
  // -------------------------------------------------------------------------
  Widget buildInsightsTab() {
    final total = records.length;
    final alignedCount = records
        .where((r) => r['hoped'] == (r['winner'] == 0 ? 'A' : 'B'))
        .length;
    final rebelledCount = records
        .where((r) =>
            r['hoped'] != 'unsure' &&
            r['hoped'] != (r['winner'] == 0 ? 'A' : 'B'))
        .length;
    final decisiveCount = alignedCount + rebelledCount;
    final clarityRate = total == 0 ? 0.0 : decisiveCount / total;
    final headsWins = records.where((r) => r['winner'] == 0).length;

    return Column(
      children: [
        sectionHeading(
          'Self-Knowledge Engine',
          'Intuition Analytics',
          'Not statistics about luck—patterns of how clearly you know your own heart.',
        ),
        const SizedBox(height: 18),

        // Hero Clarity Gauge Card
        luxuryGlass(
          child: Column(
            children: [
              SizedBox(
                height: 165,
                width: 165,
                child: CustomPaint(
                  painter: ClarityGaugePainter(
                    ratio: clarityRate,
                    primaryColor: palette.primaryGold,
                    secondaryColor: palette.tailsColor,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(clarityRate * 100).round()}%',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: palette.champagne,
                          ),
                        ),
                        Text(
                          'GUT CLARITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: palette.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                total == 0
                    ? 'Flip the coin to unlock your Intuition Index'
                    : 'In $decisiveCount of $total flips, the spinning coin immediately revealed what you truly wanted.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bento Metrics Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.toll_rounded,
                value: '$total',
                label: 'Total Tosses',
                accent: palette.primaryGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.verified_rounded,
                value: '$alignedCount',
                label: 'Fate Aligned',
                accent: const Color(0xFF4CE0B3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                icon: Icons.lightbulb_rounded,
                value: '$rebelledCount',
                label: 'Gut Overruled Coin',
                accent: const Color(0xFFFF758F),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                icon: Icons.workspace_premium_rounded,
                value: total == 0 ? '—' : '${((headsWins / total) * 100).round()}%',
                label: 'Heads Landed',
                accent: palette.headsColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        luxuryGlass(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: palette.primaryGold, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Freud observed that we don’t toss a coin to let randomness decide—we toss it because for one brief second in the air, our fear or hope strips away all rationalizations.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return luxuryGlass(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      borderAccent: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // TAB 3: ATELIER (SETTINGS & COLLECTOR SHOWCASE)
  // -------------------------------------------------------------------------
  Widget buildSettingsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionHeading(
          'Royal Atelier',
          'Craft & Atmosphere',
          'Customize the studio lighting aura, sensory feedback, and inspect the minted faces.',
        ),
        const SizedBox(height: 18),

        // Studio Lighting Aura Selector
        luxuryGlass(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_rounded, color: palette.primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ROYAL STUDIO AURA',
                    style: TextStyle(
                      color: palette.primaryGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...AuraPalette.presets.map((p) {
                final selected = p.id == auraId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() => auraId = p.id);
                      _save();
                      _sound('tap');
                      _hapticLight();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: selected
                            ? p.primaryGold.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: selected
                              ? p.primaryGold
                              : Colors.white.withValues(alpha: 0.1),
                          width: selected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [p.primaryGold, p.glowColor],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  p.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check_circle_rounded, color: p.primaryGold, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Sensory & Motion Switches
        luxuryGlass(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Column(
            children: [
              SwitchListTile(
                activeThumbColor: palette.primaryGold,
                secondary: Icon(Icons.volume_up_rounded, color: palette.primaryGold),
                title: const Text('Cinematic Acoustic Effects',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Whoosh, revolving ticks & metallic landing'),
                value: !muted,
                onChanged: (v) {
                  setState(() => muted = !v);
                  _save();
                },
              ),
              SwitchListTile(
                activeThumbColor: palette.primaryGold,
                secondary: Icon(Icons.vibration_rounded, color: palette.primaryGold),
                title: const Text('Tactile Haptic Feedback',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Feel every revolution and pedestal impact'),
                value: hapticsEnabled,
                onChanged: (v) {
                  setState(() => hapticsEnabled = v);
                  _save();
                },
              ),
              SwitchListTile(
                activeThumbColor: palette.primaryGold,
                secondary: Icon(Icons.speed_rounded, color: palette.primaryGold),
                title: const Text('Quick Toss Mode',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Shorter 1-second spin animation'),
                value: reduceMotion,
                onChanged: (v) {
                  setState(() => reduceMotion = v);
                  _save();
                },
              ),
              SwitchListTile(
                activeThumbColor: palette.primaryGold,
                secondary: Icon(Icons.visibility_off_rounded, color: palette.primaryGold),
                title: const Text('Blind Intuition Reveal',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Coin lands shrouded; tap to unveil your destiny'),
                value: blindReveal,
                onChanged: (v) {
                  setState(() => blindReveal = v);
                  _save();
                },
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFF6B8B)),
                title: const Text('Reset Decision Chronicle',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Permanently clear saved history on this device'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: palette.panel,
                      title: const Text('Clear all recorded decisions?'),
                      content: const Text('This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE63946),
                          ),
                          onPressed: () {
                            setState(() => records.clear());
                            _save();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Delete All'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Collector's Mint Showcase Card
        luxuryGlass(
          child: Column(
            children: [
              Text(
                'COLLECTOR’S MINT DISPLAY',
                style: TextStyle(
                  color: palette.primaryGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMintPreview('assets/images/coin_heads.png', 'OBVERSE · HEADS'),
                  _buildMintPreview('assets/images/coin_tails.png', 'REVERSE · TAILS'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Piloufas · Maher Ahmed Sovereign Edition · 100% Offline & Private',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMintPreview(String assetPath, String caption) {
    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.primaryGold.withValues(alpha: 0.22),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(assetPath, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          style: TextStyle(
            color: palette.champagne,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // TOP HEADER & FLOATING GLASS NAVIGATION DOCK
  // -------------------------------------------------------------------------
  Widget buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.primaryGold, palette.secondaryGold],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.primaryGold.withValues(alpha: 0.35),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFF140E02),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAHER AHMED · بيلوفاس',
                  style: TextStyle(
                    color: palette.primaryGold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const Text(
                  'Piloufas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          // Cycle Aura quick button
          IconButton(
            tooltip: 'Switch Royal Aura',
            onPressed: () {
              final idx = AuraPalette.presets.indexWhere((p) => p.id == auraId);
              final next = AuraPalette.presets[(idx + 1) % AuraPalette.presets.length];
              setState(() => auraId = next.id);
              _save();
              _sound('tap');
              _hapticLight();
            },
            icon: Icon(Icons.auto_awesome_mosaic_rounded,
                color: palette.champagne.withValues(alpha: 0.85), size: 21),
          ),
          IconButton(
            tooltip: muted ? 'Unmute Sound' : 'Mute Sound',
            onPressed: () {
              setState(() => muted = !muted);
              _save();
            },
            icon: Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: muted ? Colors.white38 : palette.primaryGold,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFloatingDock() {
    const items = [
      {'icon': Icons.toll_rounded, 'label': 'Oracle'},
      {'icon': Icons.history_edu_rounded, 'label': 'Chronicle'},
      {'icon': Icons.donut_large_rounded, 'label': 'Insights'},
      {'icon': Icons.tune_rounded, 'label': 'Atelier'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: palette.panel.withValues(alpha: 0.94),
              border: Border.all(
                color: palette.primaryGold.withValues(alpha: 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final selected = tab == i;
                final item = items[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => tab = i);
                      _sound('tap');
                      _hapticLight();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: selected
                            ? LinearGradient(
                                colors: [
                                  palette.primaryGold.withValues(alpha: 0.25),
                                  palette.secondaryGold.withValues(alpha: 0.12),
                                ],
                              )
                            : null,
                        border: selected
                            ? Border.all(
                                color: palette.primaryGold.withValues(alpha: 0.5),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 21,
                            color: selected ? palette.primaryGold : Colors.white54,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: selected ? palette.champagne : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage;
    if (tab == 0) {
      activePage = phase == 0
          ? buildHomeStage()
          : phase == 1
              ? buildFlippingStage()
              : buildResultStage();
    } else if (tab == 1) {
      activePage = buildHistoryTab();
    } else if (tab == 2) {
      activePage = buildInsightsTab();
    } else {
      activePage = buildSettingsTab();
    }

    final totalTilt = Offset(userTilt.dx + sensorTilt.dx, userTilt.dy + sensorTilt.dy);

    return AnimatedBuilder(
      animation: shakeAnim,
      builder: (context, _) {
        final shakeVal = shakeAnim.value;
        final shakeOffset = (shakeAnim.isAnimating)
            ? Offset(
                math.sin(shakeVal * math.pi * 14) * (1.0 - shakeVal) * 7.0,
                math.cos(shakeVal * math.pi * 12) * (1.0 - shakeVal) * 5.0,
              )
            : Offset.zero;

        return Transform.translate(
          offset: shakeOffset,
          child: Scaffold(
            body: Stack(
              children: [
                // Celestial Obsidian & Sovereign Gold Ambient Canvas with Gyroscope Parallax
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: ambient,
                      builder: (_, __) => CustomPaint(
                        painter: RoyalCosmosPainter(
                          t: ambient.value,
                          palette: palette,
                          tilt: totalTilt,
                        ),
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: (tab == 0 && phase != 0)
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    tooltip: 'Back to choices',
                                    onPressed: _reset,
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withValues(alpha: 0.35),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: muted ? 'Unmute' : 'Mute',
                                    onPressed: () {
                                      setState(() => muted = !muted);
                                      _save();
                                    },
                                    icon: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withValues(alpha: 0.35),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.12),
                                        ),
                                      ),
                                      child: Icon(
                                        muted
                                            ? Icons.volume_off_rounded
                                            : Icons.volume_up_rounded,
                                        size: 16,
                                        color: muted
                                            ? Colors.white38
                                            : palette.primaryGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: activePage,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            buildTopBar(),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 540),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 320),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: KeyedSubtree(
                                        key: ValueKey('tab_${tab}_phase_$phase'),
                                        child: activePage,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            buildFloatingDock(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// BESPOKE 3D-LIKE MINTED COIN PAINTER WITH PEDESTAL, SPARKS & BURST
// ---------------------------------------------------------------------------
class MintedCoinPainter extends CustomPainter {
  final double progress;
  final double ambientProgress;
  final double burstProgress;
  final bool heads;
  final bool airborne;
  final bool winningHeads;
  final List<ui.Image>? textures;
  final Offset userTilt;
  final AuraPalette palette;
  final bool shrouded;

  const MintedCoinPainter({
    required this.progress,
    required this.ambientProgress,
    required this.burstProgress,
    required this.heads,
    required this.airborne,
    required this.winningHeads,
    required this.textures,
    required this.userTilt,
    required this.palette,
    this.shrouded = false,
  });

  double _ease(double t) => Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));

  @override
  void paint(Canvas c, Size s) {
    final t = progress.clamp(0.0, 1.0);
    final cx = s.width / 2;
    final ground = s.height * 0.72;
    final radius = math.min(s.width * 0.37, s.height * 0.34);

    // 1. Flight trajectory & physics
    double lift = 0;
    if (airborne) {
      if (t < 0.74) {
        final u = t / 0.74;
        lift = -124 * 4 * u * (1 - u);
      } else if (t < 0.94) {
        final u = (t - 0.74) / 0.20;
        lift = -26 * math.pow(1 - u, 2) * math.sin(u * math.pi * 4).abs();
      }
    } else {
      // Gentle levitation breathing when idle
      lift = -5.5 * math.sin(ambientProgress * math.pi * 2);
    }

    final spinAngle = airborne
        ? (math.pi * 10 + (winningHeads ? 0 : math.pi)) *
            _ease(math.min(1, t / 0.78))
        : (heads ? 0.0 : math.pi) + userTilt.dx * 1.15;

    final wobble = airborne && t > 0.78
        ? 0.28 *
            math.sin((t - 0.78) * math.pi * 15) *
            math.pow((1 - t) / 0.22, 1.5)
        : 0.0;

    final theta = spinAngle + wobble;
    final cosA = math.cos(theta);
    final visibleHeads = cosA >= 0;
    final faceWidth = math.max(0.028, cosA.abs());

    final tilt = airborne
        ? 0.12 * math.sin(t * math.pi * 3) * math.sin(math.pi * t)
        : -0.03 + userTilt.dy * 0.45;
    final depth = airborne ? 1 + 0.15 * math.sin(math.pi * t) : 1.0;

    // 2. Royal Velvet & Gilded Pedestal on the Ground
    final heightFactor = (lift.abs() / 124).clamp(0.0, 1.0);
    final pedestalCenter = Offset(cx, ground + radius * 0.84 + 14);

    // Pedestal outer golden ring
    final pedRect = Rect.fromCenter(
      center: pedestalCenter,
      width: radius * 1.95,
      height: 34,
    );
    c.drawOval(
      pedRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.primaryGold.withValues(alpha: 0.16),
            palette.glowColor.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(pedRect),
    );
    c.drawOval(
      Rect.fromCenter(center: pedestalCenter, width: radius * 1.62, height: 22),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = palette.primaryGold.withValues(alpha: 0.28),
    );

    // Dynamic contact shadow
    c.drawOval(
      Rect.fromCenter(
        center: pedestalCenter,
        width: radius * 1.52 * (1 - heightFactor * 0.34),
        height: 16 - heightFactor * 5,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55 - heightFactor * 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + heightFactor * 14),
    );

    // 3. Airborne Golden Vortex Trail
    if (airborne && t < 0.78) {
      for (int i = 0; i < 14; i++) {
        final phaseShift = (t * 4 + i * 0.17) % 1.0;
        final sparkX = cx + math.sin(phaseShift * math.pi * 4 + i) * radius * 0.75;
        final sparkY = (ground - radius * 0.2 + lift) + phaseShift * 75;
        final alpha = (1.0 - phaseShift) * 0.55;
        c.drawCircle(
          Offset(sparkX, sparkY),
          1.5 + (i % 3) * 0.8,
          Paint()..color = palette.primaryGold.withValues(alpha: alpha),
        );
      }
    }

    // 4. Landing Shockwave & Celebratory Gold Particle Burst
    if (burstProgress > 0.0 && burstProgress < 1.0) {
      final u = Curves.easeOutCubic.transform(burstProgress);
      final ringAlpha = (1.0 - u) * 0.65;
      c.drawOval(
        Rect.fromCenter(
          center: pedestalCenter,
          width: radius * (1.2 + u * 1.6),
          height: 18 + u * 28,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - u)
          ..color = palette.primaryGold.withValues(alpha: ringAlpha),
      );

      if (u > 0.12) {
        final u2 = (u - 0.12) / 0.88;
        c.drawOval(
          Rect.fromCenter(
            center: pedestalCenter,
            width: radius * (1.1 + u2 * 2.2),
            height: 16 + u2 * 36,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 * (1 - u2)
            ..color = palette.glowColor.withValues(alpha: (1 - u2) * 0.45),
        );
      }

      final coinCenter = Offset(cx, ground - radius * 0.2 + lift);
      for (int i = 0; i < 32; i++) {
        final angle = (i / 32) * math.pi * 2 + (i % 3) * 0.15;
        final speed = radius * (0.75 + (i % 5) * 0.18);
        final px = coinCenter.dx + math.cos(angle) * speed * u;
        final py = coinCenter.dy + math.sin(angle) * speed * u + (u * u * 26);
        final pSize = (1.0 - u) * (2.2 + (i % 3));
        c.drawCircle(
          Offset(px, py),
          pSize,
          Paint()
            ..color = (i.isEven ? palette.champagne : palette.primaryGold)
                .withValues(alpha: (1.0 - u) * 0.85),
        );
      }
    }

    // 5. Volumetric Aura Halo Behind Coin
    final coinOrigin = Offset(cx, ground - radius * 0.2 + lift);
    c.drawCircle(
      coinOrigin,
      radius * 1.18,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.primaryGold.withValues(alpha: 0.18),
            palette.glowColor.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: coinOrigin, radius: radius * 1.18)),
    );

    // 6. Render 3D Minted Coin Body
    c.save();
    c.translate(coinOrigin.dx, coinOrigin.dy);
    c.rotate(tilt);

    // Matrix slow-motion apex zoom
    final apexZoom = airborne ? 1.0 + 0.14 * math.sin(t * math.pi) : 1.0;
    c.scale(depth * apexZoom);

    // Extruded metallic cylinder rim thickness
    final sinA = math.sin(theta);
    final rimThickness = 14.0 * sinA.abs();
    final rimShiftX = (sinA >= 0 ? 1 : -1) * rimThickness * 0.5;
    final edgeWidth = radius * 2 * faceWidth + rimThickness;

    final edgeRect = Rect.fromCenter(
      center: Offset(rimShiftX, 2),
      width: edgeWidth,
      height: radius * 2 + 4,
    );

    c.drawOval(
      edgeRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A2006),
            Color(0xFFD68D2C),
            Color(0xFFFFECA8),
            Color(0xFF8E4511),
            Color(0xFFFACA65),
            Color(0xFF592808),
          ],
        ).createShader(edgeRect),
    );

    // Milled coin reeding grooves along the visible edge
    if (faceWidth < 0.75) {
      final grooveCount = 18;
      for (int i = -grooveCount; i <= grooveCount; i++) {
        final frac = i / grooveCount;
        final y = frac * radius * 0.94;
        final halfW = math.sqrt(math.max(0.0, 1 - frac * frac)) * (edgeWidth / 2);
        c.drawLine(
          Offset(rimShiftX - halfW * 0.25, y),
          Offset(rimShiftX + halfW * 0.25, y),
          Paint()
            ..color = (i.isEven ? const Color(0xFFFFEAB0) : const Color(0xFF5E2B08))
                .withValues(alpha: (1 - faceWidth) * 0.45)
            ..strokeWidth = 1.2,
        );
      }
    }

    // Coin Face Disc (Never mirrored)
    c.save();
    c.scale(faceWidth, 1);
    final disc = Rect.fromCircle(center: Offset.zero, radius: radius);
    c.clipPath(Path()..addOval(disc));

    if (shrouded) {
      // Royal Velvet mystery shroud disc
      c.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFF2A101C), Color(0xFF0F050A)],
          ).createShader(disc),
      );
      // Gilded embroidered border ring
      c.drawCircle(
        Offset.zero,
        radius * 0.88,
        Paint()
          ..color = palette.primaryGold.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      // Ornate central seal crown/star
      final crownCenter = Offset(0, -radius * 0.05);
      c.drawCircle(
        crownCenter,
        radius * 0.38,
        Paint()
          ..color = palette.primaryGold.withValues(alpha: 0.14)
          ..style = PaintingStyle.fill,
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: radius * 0.52,
            fontWeight: FontWeight.w900,
            color: palette.champagne,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        c,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
    } else if (textures != null && textures!.length == 2) {
      final img = textures![visibleHeads ? 0 : 1];
      c.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        disc,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      c.drawCircle(Offset.zero, radius, Paint()..color = const Color(0xFFD5A04B));
    }

    // Dynamic Specular Light Sweep across the gold relief
    final sweepOffset = math.sin(theta + ambientProgress * math.pi * 2) * 0.65 +
        userTilt.dx * 1.4;
    final lightRect = Rect.fromLTWH(-radius, -radius, 2 * radius, 2 * radius);
    c.drawRect(
      lightRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-0.9 + sweepOffset, -1.0 + userTilt.dy),
          end: Alignment(0.9 + sweepOffset, 1.0 + userTilt.dy),
          colors: [
            Colors.white.withValues(alpha: 0.16 + 0.14 * (1 - faceWidth)),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.22),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(lightRect),
    );
    c.restore();

    // Diamond-cut rim specular glint
    if (faceWidth > 0.25) {
      c.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius * 0.985),
        -2.3 + userTilt.dx,
        0.75,
        false,
        Paint()
          ..color = palette.champagne.withValues(alpha: 0.28 + 0.35 * faceWidth)
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    c.restore();
  }

  @override
  bool shouldRepaint(covariant MintedCoinPainter old) =>
      old.progress != progress ||
      old.ambientProgress != ambientProgress ||
      old.burstProgress != burstProgress ||
      old.heads != heads ||
      old.airborne != airborne ||
      old.winningHeads != winningHeads ||
      old.userTilt != userTilt ||
      old.shrouded != shrouded ||
      old.palette.id != palette.id ||
      old.textures != textures;
}

// ---------------------------------------------------------------------------
// ROYAL COSMOS & ASTROLABE BACKGROUND PAINTER
// ---------------------------------------------------------------------------
class RoyalCosmosPainter extends CustomPainter {
  final double t;
  final AuraPalette palette;
  final Offset tilt;

  RoyalCosmosPainter({required this.t, required this.palette, required this.tilt});

  @override
  void paint(Canvas c, Size s) {
    // 1. Deep Obsidian & Royal Gradient Backdrop
    final rect = Offset.zero & s;
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.bgTop, palette.bgBottom],
        ).createShader(rect),
    );

    // 2. Ambient Golden & Aura Nebulae with Gyroscope Parallax
    final topGlowCenter = Offset(
      s.width * (0.5 + 0.12 * math.sin(t * math.pi * 2)) + tilt.dx * 30,
      s.height * 0.22 + tilt.dy * 20,
    );
    c.drawCircle(
      topGlowCenter,
      s.width * 0.65,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.glowColor.withValues(alpha: 0.11),
            palette.primaryGold.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: topGlowCenter, radius: s.width * 0.65)),
    );

    // 3. Rotating Celestial Astrolabe Rings with 3D Depth
    final center = Offset(s.width * 0.5 + tilt.dx * 36, s.height * 0.48 + tilt.dy * 24);
    final ringRadius = math.min(s.width, s.height) * 0.42;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = palette.primaryGold.withValues(alpha: 0.07);

    c.drawCircle(center, ringRadius, ringPaint);
    c.drawCircle(center, ringRadius * 1.24, ringPaint);

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 + t * math.pi * 0.5;
      final p1 = Offset(
        center.dx + math.cos(angle) * (ringRadius * 0.96),
        center.dy + math.sin(angle) * (ringRadius * 0.96),
      );
      final p2 = Offset(
        center.dx + math.cos(angle) * (ringRadius * 1.04),
        center.dy + math.sin(angle) * (ringRadius * 1.04),
      );
      c.drawLine(p1, p2, ringPaint);
    }

    // 4. Floating Sovereign Gold Embers with Gyroscope Drift
    final rng = math.Random(25);
    for (int i = 0; i < 42; i++) {
      final baseX = rng.nextDouble() * s.width;
      final baseY = rng.nextDouble() * s.height;
      final driftY = ((baseY - t * s.height * (0.15 + (i % 3) * 0.08)) + tilt.dy * 18) % s.height;
      final driftX = baseX + math.sin(t * math.pi * 2 + i) * 8 + tilt.dx * 18;
      final pulse = 0.14 + 0.42 * (0.5 + 0.5 * math.sin(t * math.pi * 2 + i * 1.3));
      final radius = i % 6 == 0 ? 1.8 : 0.95;

      c.drawCircle(
        Offset(driftX, driftY),
        radius,
        Paint()
          ..color = (i % 4 == 0 ? palette.champagne : palette.primaryGold)
              .withValues(alpha: pulse),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RoyalCosmosPainter old) =>
      old.t != t || old.palette.id != palette.id || old.tilt != tilt;
}

// ---------------------------------------------------------------------------
// INSIGHTS RADIAL GAUGE PAINTER
// ---------------------------------------------------------------------------
class ClarityGaugePainter extends CustomPainter {
  final double ratio;
  final Color primaryColor;
  final Color secondaryColor;

  ClarityGaugePainter({
    required this.ratio,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    canvas.drawArc(
      rect,
      -math.pi * 0.8,
      math.pi * 1.6,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Active progress arc
    final sweep = (math.pi * 1.6) * ratio.clamp(0.04, 1.0);
    canvas.drawArc(
      rect,
      -math.pi * 0.8,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [secondaryColor, primaryColor, Colors.white],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant ClarityGaugePainter old) =>
      old.ratio != ratio || old.primaryColor != primaryColor;
}
