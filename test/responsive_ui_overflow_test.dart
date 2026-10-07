import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_campus_placement/core/utils/application_status_helper.dart';

void main() {
  const testWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 600.0, 768.0];

  group('Responsive Layout & Overflow Tests', () {
    for (final width in testWidths) {
      testWidgets('Applicants candidate card has zero overflow on ${width}px width', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Direct candidate card test widget mirroring ApplicantsScreen card layout
        const rawDate = 'Tue Oct 06 2026 14:49:26 GMT+0530 (India Standard Time)';
        const studentName = 'JAINIL GAJJAR';
        const studentId = 'STU-2026-001';
        const role = 'Senior Full Stack Mobile Engineer';
        const email = 'jainil.gajjar.extremelylongemailaddress@university.edu';
        const mobile = '+91 9876543210';
        const skills = 'Flutter, Dart, Firebase, Python, Java, JavaScript, HTML, CSS, SQL, Git, Docker, Kubernetes';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              child: Text(studentName[0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    softWrap: true,
                                  ),
                                  const Text('Student ID: $studentId', softWrap: true),
                                  const Text('Role: $role', softWrap: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ActionChip(
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              label: const Text('Applied'),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 15),
                            const SizedBox(width: 8),
                            Expanded(child: Text(email, softWrap: true)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 15),
                            const SizedBox(width: 8),
                            Expanded(child: Text(mobile, softWrap: true)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.code_outlined, size: 15),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Skills: $skills', softWrap: true)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 15, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Applied: ${ApplicationStatusHelper.formatDisplayDateTime(rawDate)}',
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: const Text('Candidate Score: 95.0/100'),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.rate_review_outlined, size: 14),
                              label: const Text('Rate & Feedback'),
                              onPressed: () {},
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.description_outlined, size: 14),
                              label: const Text('View Resume'),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Must have ZERO exceptions and ZERO RenderFlex overflows
        expect(tester.takeException(), isNull);

        // Verify text elements exist and are rendered
        expect(find.text(studentName), findsOneWidget);
        expect(find.text('View Resume'), findsOneWidget);
        expect(find.text('Rate & Feedback'), findsOneWidget);
        expect(find.text('Candidate Score: 95.0/100'), findsOneWidget);
        expect(find.text('Applied: 06 Oct 2026, 02:49 PM'), findsOneWidget);
      });

      testWidgets('Platform Applications card has zero overflow on ${width}px width', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const rawDate = 'Tue Oct 06 2026 14:49:26 GMT+0530 (India Standard Time)';
        const studentName = 'Kashish Tank';
        const role = 'Senior Mobile Application Developer';
        const company = 'Amazon Web Services';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              child: Text(studentName[0]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$role • $company',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: const Text('Shortlisted'),
                            ),
                          ],
                        ),
                        const Divider(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Applied: ${ApplicationStatusHelper.formatDisplayDateTime(rawDate)}',
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.description_outlined, size: 14),
                              label: const Text('View Resume'),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(studentName), findsOneWidget);
        expect(find.text('View Resume'), findsOneWidget);
        expect(find.text('Applied: 06 Oct 2026, 02:49 PM'), findsOneWidget);
      });

      testWidgets('Placement Rate Breakdown card has zero overflow and normal candidate name on ${width}px width', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const rawDate = 'Tue Oct 06 2026 14:49:26 GMT+0530 (India Standard Time)';
        const studentName = 'JAINIL GAJJAR';
        const role = 'Software Engineer';
        const company = 'Google';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overall Placement Rate'),
                          const Text('28.6%'),
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Formula:'),
                                const Text(
                                  'Placement Rate = (Placed Applications / Total Applications) × 100',
                                  softWrap: true,
                                ),
                                Text(
                                  '= (2 / 7) × 100 = 28.6%',
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              child: Icon(Icons.check_circle, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 2),
                                  Text('$role • $company', softWrap: true),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 11),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ApplicationStatusHelper.formatDisplayDateTime(rawDate),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: const Text('Placed'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // Candidate name JAINIL GAJJAR must be rendered as a single normal widget
        expect(find.text(studentName), findsOneWidget);
        expect(find.text('Placed'), findsOneWidget);
        expect(find.text('06 Oct 2026, 02:49 PM'), findsOneWidget);
      });

      testWidgets('System Broadcast audience selector and history card have zero overflow on ${width}px width', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const rawDate = 'Tue Oct 06 2026 14:49:26 GMT+0530 (India Standard Time)';
        const broadcastTitle = 'Campus Placement Drive Alert: TCS Digital Hiring 2026';
        const broadcastMsg = 'All eligible students please submit your updated resume before October 15th.';
        const createdBy = 'Admin User (ADM001)';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Target Audience'),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                    child: SegmentedButton<String>(
                                      showSelectedIcon: false,
                                      style: const ButtonStyle(
                                        visualDensity: VisualDensity.compact,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      segments: const [
                                        ButtonSegment(
                                          value: 'all',
                                          label: Text('All Users', style: TextStyle(fontSize: 12)),
                                          icon: Icon(Icons.people_rounded, size: 16),
                                        ),
                                        ButtonSegment(
                                          value: 'student',
                                          label: Text('Students', style: TextStyle(fontSize: 12)),
                                          icon: Icon(Icons.school_rounded, size: 16),
                                        ),
                                        ButtonSegment(
                                          value: 'company',
                                          label: Text('Recruiters', style: TextStyle(fontSize: 12)),
                                          icon: Icon(Icons.business_rounded, size: 16),
                                        ),
                                      ],
                                      selected: const {'all'},
                                      onSelectionChanged: (_) {},
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send_rounded),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text('Send Broadcast Announcement'),
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                child: const Text('All Users'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ApplicationStatusHelper.formatDisplayDateTime(rawDate),
                                  textAlign: TextAlign.end,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(broadcastTitle, softWrap: true),
                          const SizedBox(height: 6),
                          const Text(broadcastMsg, softWrap: true),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text('Sent by $createdBy', softWrap: true),
                              ),
                            ],
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

        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Recruiters'), findsOneWidget);
        expect(find.text('Send Broadcast Announcement'), findsOneWidget);
        expect(find.text(broadcastTitle), findsOneWidget);
        expect(find.text('06 Oct 2026, 02:49 PM'), findsOneWidget);
      });
    }
  });
}
