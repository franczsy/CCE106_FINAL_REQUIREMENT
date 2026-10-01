import 'package:canteen_fx/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('app loads to the dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCanteenApp()));

    expect(find.text('University of Mindanao'), findsOneWidget);
    expect(find.text('What are you craving?'), findsOneWidget);
    expect(find.text('Chicken Meal'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);

    final dashboardScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Drinks'),
      300,
      scrollable: dashboardScrollView,
    );
    expect(find.text('Drinks'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Snacks'),
      300,
      scrollable: dashboardScrollView,
    );
    expect(find.text('Snacks'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Iced Tea'),
      300,
      scrollable: dashboardScrollView,
    );
    await tester.tap(find.text('Iced Tea'));
    await tester.pumpAndSettle();
    expect(find.text('Drinks Menu'), findsOneWidget);
  });

  testWidgets('student page shows order summary and menu sections', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SmartCanteenApp()));

    await tester.tap(find.text('Order'));
    await tester.pumpAndSettle();

    expect(find.text('Ready to order?'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Meals Menu'), findsWidgets);
  });
}
