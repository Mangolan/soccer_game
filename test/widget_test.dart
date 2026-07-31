import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soccer_game/main.dart';
import 'package:soccer_game/player_selection_screen.dart';

void main() {
  testWidgets('app opens on player selection screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(const {});

    await tester.pumpWidget(const SoccerApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PlayerSelectionScreen), findsOneWidget);
    expect(find.text('선수 선택'), findsOneWidget);
    expect(find.text('내 선수를 고르세요'), findsOneWidget);
    expect(find.text('스피드'), findsWidgets);
    expect(find.text('파워'), findsWidgets);
    expect(find.text('토끼 선수로 시작'), findsOneWidget);
  });
}
