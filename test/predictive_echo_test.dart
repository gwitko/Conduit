import 'package:conduit/features/terminal/domain/predictive_echo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PredictiveEcho laggy() =>
      PredictiveEcho()..updateSrtt(const Duration(milliseconds: 200));

  group('PredictiveEcho', () {
    test(
      'predicts printable characters at the cursor, advancing the column',
      () {
        final echo = laggy();
        echo.recordInput(
          'ls',
          inputNum: 5,
          cursorRow: 3,
          cursorColumn: 10,
          viewWidth: 80,
          altScreen: false,
        );

        final overlay = echo.overlay;
        expect(overlay.map((p) => p.character).join(), 'ls');
        expect(overlay.map((p) => p.column), [10, 11]);
        expect(overlay.every((p) => p.row == 3), isTrue);
        expect(overlay.every((p) => p.inputNum == 5), isTrue);
      },
    );

    test('hides predictions when the link is not laggy enough', () {
      final echo = PredictiveEcho()
        ..updateSrtt(const Duration(milliseconds: 5));
      echo.recordInput(
        'a',
        inputNum: 1,
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );

      expect(echo.hasPredictions, isTrue);
      expect(echo.overlay, isEmpty);
    });

    test('freezes on a control key and stops predicting', () {
      final echo = laggy();
      echo.recordInput(
        'cd\r',
        inputNum: 2,
        cursorRow: 1,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );

      expect(echo.overlay.map((p) => p.character).join(), 'cd');
      echo.recordInput(
        'x',
        inputNum: 3,
        cursorRow: 1,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );
      expect(echo.overlay.map((p) => p.character).join(), 'cd');
    });

    test('does not predict in the alternate screen', () {
      final echo = laggy();
      echo.recordInput(
        'iabc',
        inputNum: 1,
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: true,
      );
      expect(echo.overlay, isEmpty);
    });

    test('does not predict across a line wrap', () {
      final echo = laggy();
      echo.recordInput(
        'abc',
        inputNum: 1,
        cursorRow: 0,
        cursorColumn: 78,
        viewWidth: 80,
        altScreen: false,
      );
      expect(echo.overlay.map((p) => p.column), [78, 79]);
    });

    test('culls predictions the server has acknowledged', () {
      final echo = laggy();
      echo.recordInput(
        'a',
        inputNum: 4,
        cursorRow: 0,
        cursorColumn: 0,
        viewWidth: 80,
        altScreen: false,
      );
      echo.recordInput(
        'b',
        inputNum: 5,
        cursorRow: 0,
        cursorColumn: 1,
        viewWidth: 80,
        altScreen: false,
      );

      echo.recordEchoAck(4);
      expect(echo.overlay.map((p) => p.character).join(), 'b');

      echo.recordEchoAck(5);
      expect(echo.overlay, isEmpty);
      expect(echo.hasPredictions, isFalse);
    });

    test('reset clears all prediction state', () {
      final echo = laggy();
      echo.recordInput(
        'abc',
        inputNum: 1,
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
