import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfaware_app/components/editable_bio.dart';

void main() {
  testWidgets('EditableBio displays initial bio', (WidgetTester tester) async {
    const initialBio = 'This is my bio';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableBio(
          initialBio: initialBio,
          onBioChanged: (bio) {},
        ),
      ),
    ));

    expect(find.text(initialBio), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('EditableBio enters edit mode on tap',
      (WidgetTester tester) async {
    const initialBio = 'This is my bio';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableBio(
          initialBio: initialBio,
          onBioChanged: (bio) {},
        ),
      ),
    ));

    await tester.tap(find.text(initialBio));
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('EditableBio saves bio on checkmark tap',
      (WidgetTester tester) async {
    const initialBio = 'This is my bio';
    String updatedBio = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableBio(
          initialBio: initialBio,
          onBioChanged: (bio) {
            updatedBio = bio;
          },
        ),
      ),
    ));

    await tester.tap(find.text(initialBio));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Bio updated successfully!');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();

    expect(updatedBio, 'Bio updated successfully!');
    expect(find.text('Bio updated successfully!'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('EditableBio shows snackbar on save',
      (WidgetTester tester) async {
    const initialBio = 'This is my bio';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableBio(
          initialBio: initialBio,
          onBioChanged: (bio) {},
        ),
      ),
    ));

    await tester.tap(find.text(initialBio));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Updated bio');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pump();

    expect(find.text('Bio updated successfully!'), findsOneWidget);
  });
}
