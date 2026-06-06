import 'package:conduit/features/terminal/domain/terminal_string_sequence_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const esc = '\x1b';

  group('TerminalStringSequenceFilter', () {
    test('passes normal text and CSI/OSC sequences through untouched', () {
      final filter = TerminalStringSequenceFilter();
      const input = 'hello $esc[31mred$esc[0m $esc]0;title\x07 done';
      expect(filter.process(input), input);
    });

    test('strips the vim XTGETTCAP DCS probe (+q4D73) entirely', () {
      final filter = TerminalStringSequenceFilter();
      const input =
          'before$esc'
          'P+q4D73$esc\\after';
      expect(filter.process(input), 'beforeafter');
    });

    test('strips DCS terminated by the 8-bit ST', () {
      final filter = TerminalStringSequenceFilter();
      expect(filter.process('a${esc}P+q4D73\x9cb'), 'ab');
    });

    test('strips SOS, PM and APC sequences too', () {
      final filter = TerminalStringSequenceFilter();
      expect(filter.process('x${esc}Xsos$esc\\y'), 'xy');
      expect(filter.process('x$esc^pm$esc\\y'), 'xy');
      expect(filter.process('x${esc}_apc$esc\\y'), 'xy');
    });

    test('handles a sequence split across chunks', () {
      final filter = TerminalStringSequenceFilter();
      final out = StringBuffer()
        ..write(filter.process('start$esc'))
        ..write(filter.process('P+q4D'))
        ..write(filter.process('73$esc'))
        ..write(filter.process('\\end'));
      expect(out.toString(), 'startend');
    });

    test('leaves a lone escape sequence (not a string sequence) intact', () {
      final filter = TerminalStringSequenceFilter();
      expect(filter.process('${esc}c'), '${esc}c');
    });
  });
}
