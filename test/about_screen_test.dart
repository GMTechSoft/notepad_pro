import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:notepad_pro/presentation/screens/settings/about_screen.dart';

void main() {
  testWidgets('AboutScreen dynamically displays app version and build number',
      (WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'NotePilot',
      packageName: 'com.gmtechsoft.notepilot',
      version: '1.2.3',
      buildNumber: '456',
      buildSignature: '',
      installerStore: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AboutScreen(),
      ),
    );

    // Allow future from PackageInfo.fromPlatform() to complete
    await tester.pumpAndSettle();

    expect(find.text('Version 1.2.3'), findsOneWidget);

    // Scroll until the Version row in the Application Information section is visible
    await tester.scrollUntilVisible(
      find.text('Version', skipOffstage: false),
      500.0,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.2.3 (Build 456)'), findsOneWidget);
    expect(find.text('1.0.0', skipOffstage: false), findsNothing);
    expect(find.text('Build 100', skipOffstage: false), findsNothing);
  });

  testWidgets('AboutScreen displays Version Unknown when version is empty',
      (WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'NotePilot',
      packageName: 'com.gmtechsoft.notepilot',
      version: '',
      buildNumber: '',
      buildSignature: '',
      installerStore: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: AboutScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Version Unknown'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Version', skipOffstage: false),
      500.0,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
  });
}
