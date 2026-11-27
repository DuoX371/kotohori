import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/reader/reader_event.dart';

void main() {
  test('a tap carries the paragraph, offset and neighbours', () {
    final e = ReaderEvent.parse(
      '{"t":"tap","para":4,"text":"本だ。","offset":1,"before":["前。"],"after":[]}',
    );
    expect(e, isA<ReaderTap>());
    final t = e! as ReaderTap;
    expect((t.para, t.text, t.offset), (4, '本だ。', 1));
    expect(t.before, ['前。']);
    expect(t.after, isEmpty);
  });

  test('a tap says where on the screen it was (0 left … 1 right)', () {
    final t =
        ReaderEvent.parse(
              '{"t":"tap","para":0,"text":"本","offset":0,"before":[],"after":[],"x":0.8}',
            )!
            as ReaderTap;
    expect(t.x, 0.8);
    final old =
        ReaderEvent.parse(
              '{"t":"tap","para":0,"text":"本","offset":0,"before":[],"after":[]}',
            )!
            as ReaderTap;
    expect(old.x, 0.5); // unknown: middle
  });

  test('blank taps carry where they were', () {
    final b =
        ReaderEvent.parse('{"t":"blank","x":0.05,"w":1204}')! as ReaderBlank;
    expect((b.x, b.width), (0.05, 1204.0));
    expect((b.y, b.height), (0.5, 0.0)); // no height: no top band
    final full =
        ReaderEvent.parse('{"t":"blank","x":0.1,"w":1204,"y":0.02,"h":675}')!
            as ReaderBlank;
    expect((full.y, full.height), (0.02, 675.0));
    final old = ReaderEvent.parse('{"t":"blank"}')! as ReaderBlank;
    expect((old.x, old.width), (0.5, 0.0)); // unknown: the middle
    final odd =
        ReaderEvent.parse('{"t":"blank","x":"a","w":null}')! as ReaderBlank;
    expect((odd.x, odd.width), (0.5, 0.0));
  });

  test('blank, position and edge messages', () {
    expect(ReaderEvent.parse('{"t":"blank"}'), isA<ReaderBlank>());
    final pos = ReaderEvent.parse(
      '{"t":"pos","offset":120,"page":2,"pages":9}',
    );
    expect((pos! as ReaderPos).offset, 120);
    expect(((pos as ReaderPos).page, pos.pages), (2, 9));
    expect(pos.chapter, isNull);
    final inBook = ReaderEvent.parse(
      '{"t":"pos","ch":4,"offset":7,"page":0,"pages":3}',
    );
    expect((inBook! as ReaderPos).chapter, 4);
    expect(
      (ReaderEvent.parse('{"t":"edge","dir":"next"}')! as ReaderEdge).forward,
      isTrue,
    );
    expect(
      (ReaderEvent.parse('{"t":"edge","dir":"prev"}')! as ReaderEdge).forward,
      isFalse,
    );
  });

  test('anything malformed is ignored', () {
    expect(ReaderEvent.parse('not json'), isNull);
    expect(ReaderEvent.parse('{"t":"tap","para":1}'), isNull);
    expect(ReaderEvent.parse('{"t":"pos","offset":"x"}'), isNull);
    expect(ReaderEvent.parse('{"t":"edge","dir":"sideways"}'), isNull);
    expect(ReaderEvent.parse('[1,2]'), isNull);
  });
}
