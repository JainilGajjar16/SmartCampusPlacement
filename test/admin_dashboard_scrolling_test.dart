import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_placement/models/user_session.dart';
import 'package:smart_campus_placement/screens/dashboard/admin_dashboard_screen.dart';

void main() {
  setUp(() {
    UserSession().setSession(
      userId: 'ADM001',
      role: 'Admin',
      name: 'System Administrator',
      email: 'admin@campus.edu',
    );
  });

  tearDown(() {
    UserSession().clearSession();
  });

  const testWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0, 600.0, 768.0];

  group('Admin Dashboard Scrolling & Responsive Layout Tests', () {
    for (final width in testWidths) {
      testWidgets('Admin Dashboard renders with zero overflow on ${width}px width',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: AdminDashboardScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Verify top sections at start
        expect(find.text('Admin Portal'), findsOneWidget);
        expect(find.text('ID: ADM001'), findsOneWidget);
        expect(find.text('Placement Control Center'), findsOneWidget);
        expect(find.text('Key Metrics'), findsOneWidget);
        expect(find.text('Administrative Controls'), findsOneWidget);
        expect(find.text('User Management'), findsOneWidget);
        expect(find.text('System Broadcast'), findsOneWidget);

        // Scroll down to reveal and verify TabBar sections
        final scrollableFinder = find.byType(NestedScrollView);
        expect(scrollableFinder, findsOneWidget);
        await tester.drag(scrollableFinder, const Offset(0, -900));
        await tester.pumpAndSettle();

        expect(find.text('Company Approvals'), findsOneWidget);
        expect(find.text('Active Drives'), findsOneWidget);
        expect(find.text('Analytics & Reports'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Full vertical scrolling from top to bottom on Analytics tab and back',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify Top content is visible initially
      expect(find.text('Admin Portal'), findsOneWidget);
      expect(find.text('Placement Control Center'), findsOneWidget);
      expect(find.text('Key Metrics'), findsOneWidget);
      expect(find.text('Administrative Controls'), findsOneWidget);

      final scrollableFinder = find.byType(NestedScrollView);
      expect(scrollableFinder, findsOneWidget);

      // Scroll downward to bring TabBar into pinned view
      await tester.drag(scrollableFinder, const Offset(0, -900));
      await tester.pumpAndSettle();

      // 2. Switch to Tab 3: Analytics & Reports
      await tester.tap(find.widgetWithText(Tab, 'Analytics & Reports'));
      await tester.pumpAndSettle();

      // Pinned TabBar remains visible
      expect(find.widgetWithText(Tab, 'Analytics & Reports'), findsOneWidget);

      // Drag further down to scroll through analytics cards
      await tester.drag(scrollableFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify Analytics cards become visible
      expect(find.text('1. Most Demanded Skills'), findsOneWidget);

      await tester.drag(scrollableFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Top Recommended Jobs is reachable
      expect(find.text('3. Top Recommended Jobs'), findsOneWidget);

      // Drag further down to reach Placement Trends at the bottom
      await tester.drag(scrollableFinder, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('4. Placement Trends'), findsOneWidget);

      // 3. Scroll back up to the top
      await tester.drag(scrollableFinder, const Offset(0, 3000));
      await tester.pumpAndSettle();

      // Verify top header and controls are back in view
      expect(find.text('Placement Control Center'), findsOneWidget);
      expect(find.text('Administrative Controls'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tab navigation between Company Approvals, Active Drives and Analytics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(NestedScrollView);

      // Scroll to bring TabBar into pinned view
      await tester.drag(scrollableFinder, const Offset(0, -900));
      await tester.pumpAndSettle();

      // Tab 1: Company Approvals is initially selected
      expect(find.text('Review and manage company account access'), findsOneWidget);

      // Scroll inside Tab 1
      await tester.drag(scrollableFinder, const Offset(0, -100));
      await tester.pumpAndSettle();
      await tester.drag(scrollableFinder, const Offset(0, 100));
      await tester.pumpAndSettle();

      // Tap Tab 2: Active Drives
      await tester.tap(find.widgetWithText(Tab, 'Active Drives'));
      await tester.pumpAndSettle();

      // Scroll inside Tab 2
      await tester.drag(scrollableFinder, const Offset(0, -100));
      await tester.pumpAndSettle();
      await tester.drag(scrollableFinder, const Offset(0, 100));
      await tester.pumpAndSettle();

      // Tap Tab 3: Analytics & Reports
      await tester.tap(find.widgetWithText(Tab, 'Analytics & Reports'));
      await tester.pumpAndSettle();

      expect(find.text('1. Most Demanded Skills'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Horizontal swipe gesture between tabs works smoothly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(NestedScrollView);

      // Scroll to bring TabBar and TabBarView into view
      await tester.drag(scrollableFinder, const Offset(0, -900));
      await tester.pumpAndSettle();

      final tabBarViewFinder = find.byType(TabBarView);
      expect(tabBarViewFinder, findsOneWidget);

      // Swipe horizontally to switch to Tab 2
      await tester.drag(tabBarViewFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      // Swipe horizontally to switch to Tab 3
      await tester.drag(tabBarViewFinder, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('1. Most Demanded Skills'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
