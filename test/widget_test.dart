import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:south_style_app/main.dart';
import 'package:south_style_app/core/theme/app_theme.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const SouthStyleApp(),
      ),
    );

    expect(find.text('South Style'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
