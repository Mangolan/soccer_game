import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'animal_player.dart';
import 'difficulty_selection_screen.dart';

String _animalLabel(AnimalPlayer player) {
  switch (player.kind) {
    case AnimalKind.bunny:
      return '토끼 선수';
    case AnimalKind.bear:
      return '곰돌이 선수';
    case AnimalKind.duck:
      return '오리 선수';
    case AnimalKind.cat:
      return '고양이 선수';
    case AnimalKind.puppy:
      return '강아지 선수';
    case AnimalKind.seal:
      return '물범 선수';
    case AnimalKind.hamster:
      return '햄스터 선수';
    case AnimalKind.fox:
      return '여우 선수';
    case AnimalKind.panda:
      return '판다 선수';
  }
}

enum _GamePhase {
  ready,
  dropping,
  grabbing,
  lifting,
  movingToPrizeHole,
  shaking,
  failedDrop,
  successDrop,
  result,
}

enum _GripSpot { leftEar, rightEar, head, waist }

extension _GripSpotUi on _GripSpot {
  String get label {
    switch (this) {
      case _GripSpot.leftEar:
        return '왼쪽 귀 잡기';
      case _GripSpot.rightEar:
        return '오른쪽 귀 잡기';
      case _GripSpot.head:
        return '머리 잡기';
      case _GripSpot.waist:
        return '허리 잡기';
    }
  }

  double get verticalRatio {
    switch (this) {
      case _GripSpot.leftEar:
      case _GripSpot.rightEar:
        return 0.18;
      case _GripSpot.head:
        return 0.34;
      case _GripSpot.waist:
        return 0.64;
    }
  }

  double get carriedToyTop {
    switch (this) {
      case _GripSpot.leftEar:
      case _GripSpot.rightEar:
        return 114;
      case _GripSpot.head:
        return 106;
      case _GripSpot.waist:
        return 92;
    }
  }
}

bool _hasGrabFriendlyEars(AnimalKind kind) {
  return kind != AnimalKind.duck && kind != AnimalKind.seal;
}

class _CraneDisplayPlayer {
  const _CraneDisplayPlayer({
    required this.playerIndex,
    required this.x,
    required this.y,
    this.rotation = 0,
    this.scale = 1,
  });

  final int playerIndex;
  final double x;
  final double y;
  final double rotation;
  final double scale;
}

class MarbleSelectionScreen extends StatefulWidget {
  const MarbleSelectionScreen({super.key});

  static const List<AnimalPlayer> players = kAnimalPlayers;

  @override
  State<MarbleSelectionScreen> createState() => _MarbleSelectionScreenState();
}

class _MarbleSelectionScreenState extends State<MarbleSelectionScreen>
    with TickerProviderStateMixin {
  static const String _lastSelectedAnimalKey = 'last_selected_animal_index';
  static const String _privacyPolicyUrl =
      'https://mangolan.github.io/Soccer_game_policy/';

  final math.Random _random = math.Random();
  final List<_CraneDisplayPlayer> _displayPlayers =
      const <_CraneDisplayPlayer>[
        _CraneDisplayPlayer(
          playerIndex: 2,
          x: 0.12,
          y: 0.73,
          rotation: -0.08,
          scale: 1.08,
        ),
        _CraneDisplayPlayer(
          playerIndex: 1,
          x: 0.29,
          y: 0.62,
          rotation: 0.06,
          scale: 1.12,
        ),
        _CraneDisplayPlayer(
          playerIndex: 0,
          x: 0.49,
          y: 0.79,
          rotation: -0.02,
          scale: 1.02,
        ),
        _CraneDisplayPlayer(
          playerIndex: 3,
          x: 0.66,
          y: 0.64,
          rotation: 0.16,
          scale: 1.08,
        ),
        _CraneDisplayPlayer(
          playerIndex: 4,
          x: 0.84,
          y: 0.74,
          rotation: -0.08,
          scale: 1.05,
        ),
        _CraneDisplayPlayer(
          playerIndex: 5,
          x: 0.38,
          y: 0.84,
          rotation: -0.34,
          scale: 0.92,
        ),
        _CraneDisplayPlayer(
          playerIndex: 6,
          x: 0.57,
          y: 0.88,
          rotation: 0.18,
          scale: 0.90,
        ),
        _CraneDisplayPlayer(
          playerIndex: 7,
          x: 0.21,
          y: 0.88,
          rotation: -0.16,
          scale: 0.94,
        ),
        _CraneDisplayPlayer(
          playerIndex: 8,
          x: 0.79,
          y: 0.88,
          rotation: 0.14,
          scale: 0.94,
        ),
      ];

  late final AnimationController _craneController;
  late final AnimationController _danceController;

  _GamePhase _phase = _GamePhase.ready;
  double _clawX = 0.5;
  _CraneDisplayPlayer? _targetPlayer;
  _GripSpot? _gripSpot;
  final List<int?> _pickedPlayerIndices = <int?>[null, null];
  int? _lastSelectedIndex;
  bool _success = false;
  int _plays = 0;
  int _lastRegisteredPlay = -1;

  @override
  void initState() {
    super.initState();
    _craneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )
      ..addListener(_onCraneTick)
      ..addStatusListener(_onCraneStatus);
    _danceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _loadLastSelection();
  }

  @override
  void dispose() {
    _craneController.dispose();
    _danceController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIndex = prefs.getInt(_lastSelectedAnimalKey);
    if (!mounted) {
      return;
    }

    final lastSlot = _slotForIndex(storedIndex);
    setState(() {
      _lastSelectedIndex = storedIndex;
      if (lastSlot != null) {
        _clawX = lastSlot.x.clamp(0.08, 0.92);
      }
    });
  }

  _CraneDisplayPlayer? _slotForIndex(int? index) {
    if (index == null) {
      return null;
    }
    for (final slot in _displayPlayers) {
      if (slot.playerIndex == index) {
        return slot;
      }
    }
    return null;
  }

  AnimalPlayer _playerFor(_CraneDisplayPlayer displayPlayer) {
    return MarbleSelectionScreen.players[displayPlayer.playerIndex];
  }

  int get _pickedCount => _pickedPlayerIndices.whereType<int>().length;

  List<int> get _pickedConcreteIndices =>
      _pickedPlayerIndices.whereType<int>().toList(growable: false);

  AnimalPlayer? _pickedPlayerAt(int slotIndex) {
    final playerIndex = _pickedPlayerIndices[slotIndex];
    return playerIndex == null ? null : MarbleSelectionScreen.players[playerIndex];
  }

  void _onCraneTick() {
    final value = _craneController.value;
    final nextPhase = value < 0.27
        ? _GamePhase.dropping
        : value < 0.39
            ? _GamePhase.grabbing
            : value < 0.52
                ? _GamePhase.lifting
                : value < 0.70
                    ? _GamePhase.movingToPrizeHole
                        : value < 0.82
                        ? _GamePhase.shaking
                        : value < 0.90
                            ? (_success
                                ? _GamePhase.successDrop
                                : _GamePhase.failedDrop)
                            : _GamePhase.result;

    if (nextPhase != _phase) {
      setState(() {
        _phase = nextPhase;
      });
      _registerPickedPlayerWhenPrizeDrops();
    }
  }

  void _onCraneStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _phase = _GamePhase.result;
      });
      _registerPickedPlayerWhenPrizeDrops();
    }
  }

  void _registerPickedPlayerWhenPrizeDrops() {
    if (!_success || _targetPlayer == null) {
      return;
    }
    if (_phase != _GamePhase.successDrop && _phase != _GamePhase.result) {
      return;
    }
    if (_lastRegisteredPlay == _plays) {
      return;
    }

    final pickedSlot = _targetPlayer!;
    _lastRegisteredPlay = _plays;
    setState(() {
      final emptySlot = _pickedPlayerIndices.indexWhere((index) => index == null);
      if (emptySlot != -1) {
        _pickedPlayerIndices[emptySlot] = pickedSlot.playerIndex;
      }
      _lastSelectedIndex = pickedSlot.playerIndex;
    });
    _persistLastSelection(pickedSlot.playerIndex);
    HapticFeedback.mediumImpact();
  }

  Future<void> _persistLastSelection(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSelectedAnimalKey, index);
  }

  Future<void> _showRedrawDialog() async {
    if (_craneController.isAnimating || _pickedCount < 2) {
      return;
    }
    HapticFeedback.selectionClick();
    final choice = await showDialog<int>(
      context: context,
      builder: (context) => const _RedrawDialog(),
    );
    if (!mounted || choice == null) {
      return;
    }
    _prepareRedraw(choice);
  }

  void _handleRedrawTap() {
    if (_pickedCount >= 2) {
      _showRedrawDialog();
      return;
    }
    if (_pickedPlayerIndices[0] != null) {
      HapticFeedback.selectionClick();
      _prepareRedraw(0);
      return;
    }
    if (_pickedPlayerIndices[1] != null) {
      HapticFeedback.selectionClick();
      _prepareRedraw(1);
    }
  }

  void _prepareRedraw(int choice) {
    if (_craneController.isAnimating) {
      return;
    }
    setState(() {
      if (choice == 0 || choice == 2) {
        _pickedPlayerIndices[0] = null;
      }
      if (choice == 1 || choice == 2) {
        _pickedPlayerIndices[1] = null;
      }
      _phase = _GamePhase.ready;
      _targetPlayer = null;
      _gripSpot = null;
      _success = false;
      _plays = _pickedCount;
      _lastRegisteredPlay = -1;
    });
  }

  void _moveClaw(double delta) {
    if (_craneController.isAnimating) {
      return;
    }
    setState(() {
      _phase = _GamePhase.ready;
      _targetPlayer = null;
      _gripSpot = null;
      _success = false;
      _clawX = (_clawX + delta).clamp(0.08, 0.92);
    });
  }

  _CraneDisplayPlayer _nearestPlayer() {
    final pickedIndices = _pickedConcreteIndices;
    final candidates = _displayPlayers
        .where((candidate) => !pickedIndices.contains(candidate.playerIndex))
        .toList(growable: false);
    _CraneDisplayPlayer best =
        candidates.isNotEmpty ? candidates.first : _displayPlayers.first;
    var bestDistance = double.infinity;
    for (final candidate in candidates.isNotEmpty ? candidates : _displayPlayers) {
      final distance = (_clawX - candidate.x).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }
    return best;
  }

  _GripSpot _decideGripSpot(_CraneDisplayPlayer slot) {
    final offset = _clawX - slot.x;
    final kind = _playerFor(slot).kind;
    if (_hasGrabFriendlyEars(kind) && offset < -0.035) {
      return _GripSpot.leftEar;
    }
    if (_hasGrabFriendlyEars(kind) && offset > 0.035) {
      return _GripSpot.rightEar;
    }
    if (offset.abs() < 0.022) {
      return _random.nextBool() ? _GripSpot.waist : _GripSpot.head;
    }
    return _GripSpot.waist;
  }

  void _dropOrStart() {
    if (_craneController.isAnimating) {
      return;
    }
    if (_pickedCount >= 2) {
      _startGame();
      return;
    }

    final target = _nearestPlayer();
    final gripSpot = _decideGripSpot(target);
    const success = true;

    if (success) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _plays += 1;
      _phase = _GamePhase.dropping;
      _success = success;
      _targetPlayer = target;
      _gripSpot = gripSpot;
    });

    _craneController
      ..reset()
      ..forward();
  }

  Future<void> _startGame() async {
    if (_pickedCount < 2) {
      return;
    }
    final aiChoice = await _showAiSelectDialog();
    if (!mounted || aiChoice == null) {
      return;
    }

    final aiListIndex = aiChoice == 1 ? 0 : 1;
    final userListIndex = aiListIndex == 0 ? 1 : 0;
    final userIndex = _pickedPlayerIndices[userListIndex]!;
    final aiIndex = _pickedPlayerIndices[aiListIndex]!;
    final userPlayer = MarbleSelectionScreen.players[userIndex];
    final aiPlayer = MarbleSelectionScreen.players[aiIndex];

    await _persistLastSelection(userIndex);
    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DifficultySelectionScreen(
          selectedPlayer: userPlayer,
          selectedIndex: userIndex,
          aiPlayer: aiPlayer,
          aiIndex: aiIndex,
        ),
      ),
    );
  }

  Future<int?> _showAiSelectDialog() async {
    if (_pickedCount < 2) {
      return null;
    }

    var selected = 1;
    final firstPlayer = MarbleSelectionScreen.players[_pickedPlayerIndices[0]!];
    final secondPlayer = MarbleSelectionScreen.players[_pickedPlayerIndices[1]!];

    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'AI 선수를 고르세요',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<int>(
                      value: 1,
                      groupValue: selected,
                      onChanged: (value) {
                        setDialogState(() => selected = value ?? 1);
                      },
                      title: const Text('첫번째 선수'),
                      subtitle: Text(_animalLabel(firstPlayer)),
                      secondary: SizedBox(
                        width: 42,
                        height: 42,
                        child: AnimalPlush(
                          player: firstPlayer,
                          size: 38,
                          soccerUniform: true,
                        ),
                      ),
                    ),
                    RadioListTile<int>(
                      value: 2,
                      groupValue: selected,
                      onChanged: (value) {
                        setDialogState(() => selected = value ?? 2);
                      },
                      title: const Text('두번째 선수'),
                      subtitle: Text(_animalLabel(secondPlayer)),
                      secondary: SizedBox(
                        width: 42,
                        height: 42,
                        child: AnimalPlush(
                          player: secondPlayer,
                          size: 38,
                          soccerUniform: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_privacyPolicyUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String get _mainButtonLabel {
    if (_pickedCount >= 2) {
      return '게임시작';
    }
    return '뽑기!';
  }

  String get _puppyLine {
    if (_pickedCount >= 2) {
      return '두 선수가 준비 완료! 게임시작을 눌러 1:1 대결을 시작해보세요!';
    }
    if (_pickedCount == 1) {
      if (_pickedPlayerIndices[0] == null) {
        return '첫 번째 선수를 다시 뽑아보세요!';
      }
      if (_pickedPlayerIndices[1] == null) {
        return '마음에 들면 다음 선수를 뽑아보세요!';
      }
      return '첫 번째 선수가 나왔어요! 두 번째 선수를 뽑아보세요!';
    }

    switch (_phase) {
      case _GamePhase.ready:
        return '멍! 오늘은 귀여운 선수를 뽑아보자!';
      case _GamePhase.dropping:
        return '어디를 집을지 조심조심 내려가는 중...';
      case _GamePhase.grabbing:
        return '좋아, 집게가 장난감을 잡았어!';
      case _GamePhase.lifting:
        return '조금만 더, 위로 올라간다!';
      case _GamePhase.movingToPrizeHole:
        return '출구 쪽으로 천천히 이동 중!';
      case _GamePhase.shaking:
        return '흔들흔들... 떨어지지 마!';
      case _GamePhase.failedDrop:
        return '앗, 아쉽게 놓쳤어... 다시 도전!';
      case _GamePhase.successDrop:
        return '성공! 선수 입장 준비 완료!';
      case _GamePhase.result:
        return _success && _targetPlayer != null
            ? '${_animalLabel(_playerFor(_targetPlayer!))} 획득!'
            : '아쉽지만 다음 판에서 다시 해보자!';
    }
  }

  bool get _isBusy => _craneController.isAnimating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F2),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final firstPlayer = _pickedPlayerAt(0);
            final secondPlayer = _pickedPlayerAt(1);
            final secondPickInProgress = _pickedCount == 1 &&
                _plays > _pickedCount &&
                _targetPlayer != null &&
                _craneController.isAnimating;

            return Padding(
              padding: EdgeInsets.fromLTRB(12, compact ? 4 : 8, 12, 8),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      _Header(compact: compact),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          tooltip: '개인정보처리방침',
                          onPressed: _openPrivacyPolicy,
                          icon: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Color(0xFF8A6258),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Expanded(
                    flex: 5,
                    child: AnimatedBuilder(
                      animation: _craneController,
                      builder: (context, _) {
                        return _CraneMachine(
                          players: MarbleSelectionScreen.players,
                          displayPlayers: _displayPlayers,
                          controllerValue: _craneController.value,
                          clawX: _clawX,
                          phase: _phase,
                          pickedPlayerIndices: _pickedConcreteIndices,
                          targetPlayer: _targetPlayer,
                          success: _success,
                          gripSpot: _gripSpot,
                        );
                      },
                    ),
                  ),
                  SizedBox(height: compact ? 5 : 8),
                  Expanded(
                    flex: 3,
                    child: AnimatedBuilder(
                      animation: _danceController,
                      builder: (context, _) {
                        return _PreviewStage(
                          firstPlayer: firstPlayer,
                          secondPlayer: secondPlayer,
                          secondPickInProgress: secondPickInProgress,
                          danceValue: _danceController.value,
                        );
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _pickedCount == 0
                        ? SizedBox(height: compact ? 4 : 6)
                        : Padding(
                            padding: EdgeInsets.only(
                              top: compact ? 4 : 6,
                              bottom: compact ? 2 : 4,
                            ),
                            child: _RedrawButton(
                              disabled: _isBusy,
                              onTap: _handleRedrawTap,
                            ),
                          ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  _PuppyMessage(line: _puppyLine),
                  SizedBox(height: compact ? 4 : 6),
                  _Controls(
                    disabled: _isBusy,
                    mainLabel: _mainButtonLabel,
                    readyToStart: _pickedCount >= 2,
                    onLeft: () => _moveClaw(-0.09),
                    onRight: () => _moveClaw(0.09),
                    onMain: _dropOrStart,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _HeaderBearIcon(),
            const SizedBox(width: 8),
            Text(
              '선수뽑기',
              style: TextStyle(
                fontSize: compact ? 25 : 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF4B312A),
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(width: 8),
            const _HeaderBearIcon(),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 4),
          const Text(
            '집게로 선수를 뽑고 1:1 대결을 시작하세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8A6258),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderBearIcon extends StatelessWidget {
  const _HeaderBearIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 38,
      child: AnimalPlush(
        player: MarbleSelectionScreen.players[1],
        size: 34,
      ),
    );
  }
}

class _PuppyMessage extends StatelessWidget {
  const _PuppyMessage({required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey<String>(line),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD5DD), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12B56A7A),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          line,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w900,
            color: Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }
}

class _CraneMachine extends StatelessWidget {
  const _CraneMachine({
    required this.players,
    required this.displayPlayers,
    required this.controllerValue,
    required this.clawX,
    required this.phase,
    required this.pickedPlayerIndices,
    required this.targetPlayer,
    required this.success,
    required this.gripSpot,
  });

  final List<AnimalPlayer> players;
  final List<_CraneDisplayPlayer> displayPlayers;
  final double controllerValue;
  final double clawX;
  final _GamePhase phase;
  final List<int> pickedPlayerIndices;
  final _CraneDisplayPlayer? targetPlayer;
  final bool success;
  final _GripSpot? gripSpot;

  double _segment(double t, double start, double end) {
    if (t <= start) {
      return 0;
    }
    if (t >= end) {
      return 1;
    }
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final glassTop = 60.0;
        final glassBottom = 58.0;
        final glassHeight = math.max(120.0, height - glassTop - glassBottom);
        final toyBaseTop = glassHeight * 0.46;
        final target = targetPlayer;

        final prizeHoleX = width * 0.78;
        final prizeHoleY = glassHeight * 0.84;
        final railY = 34.0;
        final targetX = target?.x ?? clawX;
        final targetToyY =
            target == null ? toyBaseTop + 0.70 * 34 : toyBaseTop + target.y * 34;

        final down = Curves.easeInOut.transform(
          _segment(controllerValue, 0.00, 0.27),
        );
        final lift = Curves.easeInOut.transform(
          _segment(controllerValue, 0.39, 0.52),
        );
        final moveHole = Curves.easeInOut.transform(
          _segment(controllerValue, 0.52, 0.70),
        );
        final drop = Curves.easeIn.transform(
          _segment(controllerValue, 0.82, 0.90),
        );
        final returnHome = Curves.easeOutCubic.transform(
          _segment(controllerValue, 0.90, 1.00),
        );

        final targetToyHeight = (target?.scale ?? 1.0) * 64 * 1.08;
        final activeGripSpot = gripSpot ?? _GripSpot.waist;
        final gripPointY = targetToyY + targetToyHeight * activeGripSpot.verticalRatio;
        final maxDropToToy =
            (gripPointY - railY - 126).clamp(20.0, glassHeight * 0.44);

        final clawXBeforeHole = (width - 72) * targetX;
        final clawXAtHole = prizeHoleX - 36;
        final clawXHome = (width - 72) * clawX;
        final clawLeft = phase == _GamePhase.ready ||
                phase == _GamePhase.dropping ||
                phase == _GamePhase.grabbing ||
                phase == _GamePhase.lifting
            ? clawXHome
            : phase == _GamePhase.result
                ? _lerp(clawXAtHole, clawXHome, returnHome)
                : _lerp(clawXBeforeHole, clawXAtHole, moveHole);

        final clawTop = railY + (down * maxDropToToy) - (lift * maxDropToToy);
        final shakeOffset = phase == _GamePhase.shaking
            ? math.sin(controllerValue * 90) * 6
            : 0.0;
        final successDropLeft = prizeHoleX - 32;
        final successDropTop = prizeHoleY - 38 + drop * 58;
        final failDropLeft = clawLeft + 7 + shakeOffset + math.sin(controllerValue * 28) * 18;
        final failDropTop = clawTop + activeGripSpot.carriedToyTop + drop * 95;
        final droppedPlayerLeft = success ? successDropLeft : failDropLeft;
        final droppedPlayerTop = success ? successDropTop : failDropTop;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB4C8), Color(0xFFFFD89E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6D4C41),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: _MachineTopBanner(
                    phase: phase,
                    success: success,
                    player: success && target != null
                        ? players[target.playerIndex]
                        : pickedPlayerIndices.isNotEmpty
                            ? players[pickedPlayerIndices.last]
                            : null,
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  top: glassTop,
                  bottom: glassBottom,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF8FDFF), Color(0xFFFFF0E9)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 20,
                            right: 20,
                            top: 22,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF9E6E5A),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -20,
                            top: 20,
                            child: Transform.rotate(
                              angle: -0.22,
                              child: Container(
                                width: 70,
                                height: height,
                                color: Colors.white.withOpacity(0.24),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: glassHeight * 0.31,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFC86B),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: prizeHoleX - 60,
                            top: prizeHoleY - 18,
                            child: const _PrizeHole(),
                          ),
                          if (phase == _GamePhase.dropping ||
                              phase == _GamePhase.grabbing)
                            Positioned(
                              left: 18,
                              top: 42,
                              child: _GripBadge(label: activeGripSpot.label),
                            ),
                          for (final displayPlayer in displayPlayers)
                            if (!_hideFloorPlayer(displayPlayer))
                              Positioned(
                                left: displayPlayer.x * (width - 104),
                                top: toyBaseTop + displayPlayer.y * 34,
                                child: Transform.rotate(
                                  angle: displayPlayer.rotation,
                                  child: AnimalPlush(
                                    player: players[displayPlayer.playerIndex],
                                    size: 60 * displayPlayer.scale,
                                    soccerUniform: true,
                                  ),
                                ),
                              ),
                          if ((phase == _GamePhase.failedDrop ||
                                  phase == _GamePhase.successDrop) &&
                              target != null)
                            Positioned(
                              left: droppedPlayerLeft,
                              top: droppedPlayerTop,
                              child: Transform.rotate(
                                angle: success
                                    ? 0
                                    : math.sin(controllerValue * 32) * 0.35,
                                child: AnimalPlush(
                                  player: players[target.playerIndex],
                                  size: 58 * target.scale,
                                  soccerUniform: true,
                                ),
                              ),
                            ),
                          Positioned(
                            left: clawLeft + shakeOffset,
                            top: clawTop,
                            child: _Claw(
                              phase: phase,
                              player: target == null
                                  ? null
                                  : players[target.playerIndex],
                              showPlayer: _showCarriedPlayer,
                              gripSpot: activeGripSpot,
                              shakeValue: controllerValue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 14,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B312A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            '출구',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 52,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF176),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Color(0xFF6D4C41),
                        ),
                      ),
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

  bool get _showCarriedPlayer {
    return phase == _GamePhase.lifting ||
        phase == _GamePhase.movingToPrizeHole ||
        phase == _GamePhase.shaking;
  }

  bool _hideFloorPlayer(_CraneDisplayPlayer player) {
    if (pickedPlayerIndices.contains(player.playerIndex)) {
      return true;
    }
    if (targetPlayer?.playerIndex != player.playerIndex) {
      return false;
    }
    return phase == _GamePhase.lifting ||
        phase == _GamePhase.movingToPrizeHole ||
        phase == _GamePhase.shaking ||
        phase == _GamePhase.failedDrop ||
        phase == _GamePhase.successDrop ||
        phase == _GamePhase.result;
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _MachineTopBanner extends StatelessWidget {
  const _MachineTopBanner({
    required this.phase,
    required this.success,
    required this.player,
  });

  final _GamePhase phase;
  final bool success;
  final AnimalPlayer? player;

  @override
  Widget build(BuildContext context) {
    final isResult = phase == _GamePhase.result;
    final title = isResult
        ? (success && player != null
            ? '${_animalLabel(player!)} 획득!'
            : '아쉽지만 다시 도전!')
        : '럭키 선수뽑기';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey<String>(title),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isResult
              ? const Color(0xFFFFEEF4)
              : const Color(0xFFFFF0A8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isResult ? const Color(0xFFFF9DB8) : Colors.transparent,
            width: isResult ? 1.5 : 0,
          ),
        ),
        child: Center(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5D4037),
            ),
          ),
        ),
      ),
    );
  }
}

class _GripBadge extends StatelessWidget {
  const _GripBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFF9DB8), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.ads_click_rounded,
            size: 13,
            color: Color(0xFFB64A67),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF6D4C41),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeHole extends StatelessWidget {
  const _PrizeHole();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 15,
            child: Container(
              width: 104,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const RadialGradient(
                  center: Alignment(0, 0.15),
                  radius: 0.72,
                  colors: [
                    Color(0xFF2F1714),
                    Color(0xFF4B2420),
                    Color(0xFF8A4A42),
                  ],
                  stops: [0.0, 0.58, 1.0],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 14,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 7,
            child: Container(
              width: 112,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFB6C8),
                    Color(0xFFFF7FA1),
                    Color(0xFFD94F78),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            child: Container(
              width: 88,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6C302B),
                    Color(0xFF2B1210),
                    Color(0xFF160908),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF4),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFFF9DB8),
                  width: 1.5,
                ),
              ),
              child: const Text(
                'OUT',
                style: TextStyle(
                  color: Color(0xFFB64A67),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Claw extends StatelessWidget {
  const _Claw({
    required this.phase,
    required this.player,
    required this.showPlayer,
    required this.gripSpot,
    required this.shakeValue,
  });

  final _GamePhase phase;
  final AnimalPlayer? player;
  final bool showPlayer;
  final _GripSpot gripSpot;
  final double shakeValue;

  @override
  Widget build(BuildContext context) {
    final closed = phase == _GamePhase.grabbing ||
        phase == _GamePhase.lifting ||
        phase == _GamePhase.movingToPrizeHole ||
        phase == _GamePhase.shaking;
    final squeezing = phase == _GamePhase.grabbing
        ? math.sin(shakeValue * 70).abs() * 0.22
        : 0.0;
    final openForDrop = phase == _GamePhase.failedDrop ||
            phase == _GamePhase.successDrop
        ? 0.48
        : 0.0;
    final angle = closed ? 0.32 - squeezing + openForDrop : 0.88;

    return SizedBox(
      width: 72,
      height: 150,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 7,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFB0BEC5),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Positioned(
            top: 70,
            child: Container(
              width: 42,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF90A4AE),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned(
            top: 88,
            left: 17,
            child: Transform.rotate(
              angle: -angle,
              alignment: Alignment.topCenter,
              child: const _ClawFinger(),
            ),
          ),
          Positioned(
            top: 88,
            right: 17,
            child: Transform.rotate(
              angle: angle,
              alignment: Alignment.topCenter,
              child: const _ClawFinger(),
            ),
          ),
          if (showPlayer && player != null)
            Positioned(
              top: gripSpot.carriedToyTop,
              child: Transform.rotate(
                angle: phase == _GamePhase.shaking
                    ? math.sin(shakeValue * 90) * 0.22
                    : 0,
                child: Transform.scale(
                  scale: 0.78,
                  child: AnimalPlush(
                    player: player!,
                    size: 58,
                    soccerUniform: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClawFinger extends StatelessWidget {
  const _ClawFinger();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF78909C),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _PreviewStage extends StatelessWidget {
  const _PreviewStage({
    required this.firstPlayer,
    required this.secondPlayer,
    required this.secondPickInProgress,
    required this.danceValue,
  });

  final AnimalPlayer? firstPlayer;
  final AnimalPlayer? secondPlayer;
  final bool secondPickInProgress;
  final double danceValue;

  @override
  Widget build(BuildContext context) {
    final hasP1 = firstPlayer != null;
    final hasP2 = secondPlayer != null;
    final leftPlayer = firstPlayer;
    final rightPlayer = secondPlayer;
    final showVersus = leftPlayer != null && rightPlayer != null;
    final showSecondPlaceholder = hasP1 && !hasP2 && !secondPickInProgress;
    final showFirstPlaceholder = !hasP1 && hasP2;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF29163E), Color(0xFF101B3F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: const Color(0xFFFFC2CF), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          final cardHeight = constraints.maxHeight;
          final plushSize = math.min(cardWidth * 0.23, cardHeight * 0.50)
              .clamp(52.0, 92.0);
          final bounce = math.sin(danceValue * math.pi * 2);
          final lift = bounce * 8;

          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _StageSparklePainter(danceValue),
                ),
              ),
              Positioned(
                left: 18,
                top: 12,
                child: const _PlayerBadge(
                  label: 'PLAYER 1',
                  color: Color(0xFFFF6F91),
                ),
              ),
              Positioned(
                right: 18,
                top: 12,
                child: const _PlayerBadge(
                  label: 'PLAYER 2',
                  color: Color(0xFF5C8DFF),
                ),
              ),
              if (leftPlayer != null)
                Positioned(
                  left: cardWidth * 0.10,
                  top: cardHeight * 0.25 + lift,
                  child: _DancingPlayer(
                    player: leftPlayer,
                    size: plushSize,
                    value: danceValue,
                    flip: false,
                  ),
                ),
              if (rightPlayer != null)
                Positioned(
                  right: cardWidth * 0.10,
                  top: cardHeight * 0.25 - lift,
                  child: _DancingPlayer(
                    player: rightPlayer,
                    size: plushSize,
                    value: danceValue + 0.33,
                    flip: true,
                  ),
                ),
              if (!hasP1 && !hasP2)
                const Center(
                  child: Text(
                    '첫 번째 선수를 뽑아보세요!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              if (showFirstPlaceholder)
                Positioned(
                  left: cardWidth * 0.12,
                  top: cardHeight * 0.40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(.28),
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      'PLAYER 1\n다시 뽑기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD7C9FF),
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              if (showSecondPlaceholder)
                Positioned(
                  right: cardWidth * 0.12,
                  top: cardHeight * 0.40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(.28),
                        width: 1.5,
                      ),
                    ),
                    child: const Text(
                      'PLAYER 2\n준비중',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD7C9FF),
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              if (showVersus)
                Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: math.min(cardWidth * 0.09, 32),
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFD46B),
                      shadows: const [
                        Shadow(
                          color: Color(0xAAFF6F00),
                          blurRadius: 8,
                        ),
                        Shadow(
                          color: Color(0xAA000000),
                          blurRadius: 3,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              if (leftPlayer != null)
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: _NamePlate(
                    label: _animalLabel(leftPlayer),
                    color: const Color(0xFFFFAEC4),
                  ),
                ),
              if (rightPlayer != null)
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: _NamePlate(
                    label: _animalLabel(rightPlayer),
                    color: const Color(0xFFAED0FF),
                  ),
                ),
              if (showSecondPlaceholder)
                Positioned(
                  right: 18,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.28),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(.22),
                      ),
                    ),
                    child: const Text(
                      '두 번째 선수를 뽑아보세요!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerBadge extends StatelessWidget {
  const _PlayerBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.65), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _NamePlate extends StatelessWidget {
  const _NamePlate({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.8), width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4B312A),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DancingPlayer extends StatelessWidget {
  const _DancingPlayer({
    required this.player,
    required this.size,
    required this.value,
    required this.flip,
  });

  final AnimalPlayer player;
  final double size;
  final double value;
  final bool flip;

  @override
  Widget build(BuildContext context) {
    final t = value * math.pi * 2;
    final angle = math.sin(t) * 0.12;
    final scale = 1.0 + math.sin(t + 0.7).abs() * 0.05;

    return Transform.scale(
      scaleX: flip ? -scale : scale,
      scaleY: scale,
      child: Transform.rotate(
        angle: angle,
        child: AnimalPlush(
          player: player,
          size: size,
          soccerUniform: true,
        ),
      ),
    );
  }
}

class _StageSparklePainter extends CustomPainter {
  _StageSparklePainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final stars = <Offset>[
      Offset(size.width * .18, size.height * .28),
      Offset(size.width * .36, size.height * .18),
      Offset(size.width * .53, size.height * .42),
      Offset(size.width * .73, size.height * .25),
      Offset(size.width * .84, size.height * .58),
      Offset(size.width * .25, size.height * .72),
    ];

    for (var i = 0; i < stars.length; i++) {
      final pulse = .55 + .45 * math.sin(value * math.pi * 2 + i);
      paint.color = Color.lerp(
        const Color(0xFFFFE27A),
        const Color(0xFFFF7AC9),
        i / stars.length,
      )!
          .withOpacity(.45 + .35 * pulse);
      _drawStar(canvas, stars[i], 4 + pulse * 3, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final innerRadius = i.isEven ? radius : radius * .38;
      final point = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * innerRadius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StageSparklePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _RedrawDialog extends StatelessWidget {
  const _RedrawDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F2),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFB8C8), width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9EB5), Color(0xFFFF6F91)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Icon(
                Icons.shuffle_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '누구를 다시 뽑을까요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4B312A),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            _RedrawDialogOption(
              icon: Icons.looks_one_rounded,
              label: '첫 번째 플레이어 다시 뽑기',
              color: Color(0xFFFF6F91),
              onTap: () => Navigator.pop(context, 0),
            ),
            const SizedBox(height: 9),
            _RedrawDialogOption(
              icon: Icons.looks_two_rounded,
              label: '두 번째 플레이어 다시 뽑기',
              color: Color(0xFF5C8DFF),
              onTap: () => Navigator.pop(context, 1),
            ),
            const SizedBox(height: 9),
            _RedrawDialogOption(
              icon: Icons.groups_rounded,
              label: '둘 다 다시 뽑기',
              color: Color(0xFF30B24C),
              onTap: () => Navigator.pop(context, 2),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Color(0xFF8A6258),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RedrawDialogOption extends StatelessWidget {
  const _RedrawDialogOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(.28), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF4B312A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RedrawButton extends StatelessWidget {
  const _RedrawButton({
    required this.disabled,
    required this.onTap,
  });

  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: disabled ? .45 : 1,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFB8C8), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shuffle_rounded,
                color: Color(0xFFFF6F91),
                size: 21,
              ),
              SizedBox(width: 7),
              Text(
                '다시 뽑기',
                style: TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.disabled,
    required this.mainLabel,
    required this.readyToStart,
    required this.onLeft,
    required this.onRight,
    required this.onMain,
  });

  final bool disabled;
  final String mainLabel;
  final bool readyToStart;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onMain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8D9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFC6D0), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundControlButton(
                  icon: Icons.arrow_back_rounded,
                  disabled: disabled,
                  onTap: onLeft,
                ),
                const SizedBox(width: 12),
                _RoundControlButton(
                  icon: Icons.arrow_forward_rounded,
                  disabled: disabled,
                  onTap: onRight,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: disabled ? null : onMain,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: readyToStart
                        ? const [Color(0xFF8CE35F), Color(0xFF30B24C)]
                        : const [Color(0xFFFFD15C), Color(0xFFFF9F1C)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(.7),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      readyToStart
                          ? Icons.sports_soccer
                          : Icons.pan_tool_alt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mainLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 3,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.icon,
    required this.disabled,
    required this.onTap,
  });

  final IconData icon;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: disabled ? .45 : 1,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9EB5), Color(0xFFFF6F91)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(.72), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
