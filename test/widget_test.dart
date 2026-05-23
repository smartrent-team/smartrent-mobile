import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartrent_mobile/main.dart';

void main() {
  testWidgets('HomeTanent renders correctly and expands bill card details', (WidgetTester tester) async {
    // Set a taller window size to prevent scrolling issues in test environment
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('Xin chào 👋'), findsOneWidget);
    expect(find.text('Tiền phòng'), findsOneWidget);
    expect(find.text('Tiền điện'), findsOneWidget);
    expect(find.text('Tiền nước'), findsOneWidget);

    // Prior to expansion, Internet and Phí dịch vụ should not be visible
    expect(find.text('Internet'), findsNothing);
    expect(find.text('Phí dịch vụ'), findsNothing);

    // Ensure expanded button is visible & tap it
    final expandButton = find.text('Xem thêm 2 khoản ▼');
    await tester.ensureVisible(expandButton);
    await tester.tap(expandButton);
    await tester.pumpAndSettle();

    // Now they should be rendered
    expect(find.text('Internet'), findsOneWidget);
    expect(find.text('Phí dịch vụ'), findsOneWidget);
    expect(find.text('120.000 đ'), findsOneWidget);
    expect(find.text('140.000 đ'), findsOneWidget);

    // Tap to collapse
    final collapseButton = find.text('Thu gọn ▲');
    await tester.ensureVisible(collapseButton);
    await tester.tap(collapseButton);
    await tester.pumpAndSettle();

    // Should disappear again
    expect(find.text('Internet'), findsNothing);
  });
}
