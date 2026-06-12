import 'package:conduit/features/terminal/domain/predictive_echo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PredictiveEcho newEcho() => PredictiveEcho();

  group('PredictiveEcho', () {
    test(
      'predicts printable characters at the cursor, advancing the column',
      () {
        final predictiveEcho = newEcho();
        predictiveEcho.recordInput(
          'ls',
          cursorRow: 3,
          cursorColumn: 10,
          viewWidth: 80,
          altScreen: false,
        );

        final overlay = predictiveEcho.overlay;
        expect(overlay.map((p) => p.character).join(), 'ls');
        expect(overlay.map((p) => p.column), [10, 11]);
        expect(overlay.every((p) => p.row == 3), isTrue);
      },
    );

    test('shows predictions consistently after input', () {
      final predictiveEcho = newEcho();
      predictiveEcho.recordInput(
        'a',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );

      expect(predictiveEcho.hasPredictions, isTrue);
      expect(predictiveEcho.overlay.map((p) => p.character).join(), 'a');
    });

    test('shows predictions before the first RTT sample', () {
      final predictiveEcho = PredictiveEcho();
      predictiveEcho.recordInput(
        'a',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );

      expect(predictiveEcho.overlay.map((p) => p.character).join(), 'a');
    });

    test('resumes prediction after a control key freeze', () {
      final echo = newEcho();
      echo.recordInput(
        'cd\r',
        cursorRow: 1,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );

      expect(echo.overlay.map((p) => p.character).join(), 'cd');
      echo.recordInput(
        'x',
        cursorRow: 2,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );
      expect(echo.overlay.map((p) => p.character).join(), 'x');
      expect(echo.overlay.single.row, 2);
      expect(echo.overlay.single.column, 0);
    });

    test('backspace retracts pending predictions', () {
      final echo = newEcho();
      echo.recordInput(
        'abc',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );
      echo.recordInput(
        '\x7f',
        cursorRow: 0,
        cursorColumn: 3,
        viewWidth: 80,
        altScreen: false,
      );

      expect(echo.overlay.map((p) => p.character).join(), 'ab');
      expect(echo.overlay.map((p) => p.column), [0, 1]);
    });

    test('typing after backspace resumes at the retracted column', () {
      final echo = newEcho();
      echo.recordInput(
        'ab',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );
      echo.recordInput(
        '\b',
        cursorRow: 0,
        cursorColumn: 2,
        viewWidth: 80,
        altScreen: false,
      );
      echo.recordInput(
        'c',
        cursorRow: 0,
        cursorColumn: 1,
        viewWidth: 80,
        altScreen: false,
      );

      expect(echo.overlay.map((p) => p.character).join(), 'ac');
      expect(echo.overlay.map((p) => p.column), [0, 1]);
    });

    test('backspace over confirmed text predicts an erased cell', () {
      final echo = newEcho();
      echo.recordInput(
        'abc',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );
      echo.removeWhere((_) => true);
      echo.recordInput(
        '\x7f',
        cursorRow: 0,
        cursorColumn: 3,
        viewWidth: 80,
        altScreen: false,
      );

      final overlay = echo.overlay;
      expect(overlay, hasLength(1));
      expect(overlay.single.row, 0);
      expect(overlay.single.column, 2);
      expect(overlay.single.character, isEmpty);
      expect(overlay.single.erase, isTrue);
    });

    test('typing after deleting confirmed text replaces the erased cell', () {
      final echo = newEcho();
      echo.recordInput(
        'abc',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );
      echo.removeWhere((_) => true);
      echo.recordInput(
        '\x7f',
        cursorRow: 0,
        cursorColumn: 3,
        viewWidth: 80,
        altScreen: false,
      );
      echo.recordInput(
        'x',
        cursorRow: 0,
        cursorColumn: 2,
        viewWidth: 80,
        altScreen: false,
      );

      expect(echo.overlay.map((p) => p.column), [2, 2]);
      expect(echo.overlay.map((p) => p.erase), [true, false]);
      expect(echo.overlay.map((p) => p.character), ['', 'x']);
    });

    test('does not predict erasing past the input start column', () {
      final echo = newEcho();
      echo.recordInput(
        'hi',
        cursorRow: 0,
        cursorColumn: 5,
        viewWidth: 80,
        altScreen: false,
      );
      echo.recordInput(
        '\x7f',
        cursorRow: 0,
        cursorColumn: 7,
        viewWidth: 80,
        altScreen: false,
      );
      echo.recordInput(
        '\x7f',
        cursorRow: 0,
        cursorColumn: 6,
        viewWidth: 80,
        altScreen: false,
      );
      echo.recordInput(
        '\x7f',
        cursorRow: 0,
        cursorColumn: 5,
        viewWidth: 80,
        altScreen: false,
      );

      expect(echo.overlay, isEmpty);
    });

    test('backspacing at a fresh prompt predicts nothing', () {
      final echo = newEcho();
      echo.recordInput(
        '\x7f',
        cursorRow: 0,
        cursorColumn: 12,
        viewWidth: 80,
        altScreen: false,
      );

      expect(echo.overlay, isEmpty);
    });

    test('does not predict in the alternate screen', () {
      final echo = newEcho();
      echo.recordInput(
        'iabc',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: true,
      );
      expect(echo.overlay, isEmpty);
    });

    test('does not predict across a line wrap', () {
      final echo = newEcho();
      echo.recordInput(
        'abc',
        cursorRow: 0,
        cursorColumn: 78,
        viewWidth: 80,
        altScreen: false,
      );
      expect(echo.overlay.map((p) => p.column), [78, 79]);
    });

    test('removes predictions confirmed by terminal output', () {
      final echo = newEcho();
      echo.recordInput(
        'ab',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );

      echo.removeWhere((prediction) => prediction.column == 0);

      expect(echo.overlay.map((p) => p.character).join(), 'b');
    });

    test('reset clears all prediction state', () {
      final echo = newEcho();
      echo.recordInput(
        'abc',
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );
      echo.reset();
      expect(echo.hasPredictions, isFalse);
      expect(echo.overlay, isEmpty);
    });
  });
}
