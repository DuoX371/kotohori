import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/home/display_name.dart';

void main() {
  test('strips release tags', () {
    expect(
      displayName(
        '[Erai-raws] Re Zero kara Hajimeru Isekai Seikatsu 4th Season - 02 [1080p CR WEBRip HEVC AAC][MultiSub][59BECD96].mkv',
      ),
      'Re Zero kara Hajimeru Isekai Seikatsu 4th Season - 02',
    );
    expect(
      displayName(
        '[shincaps] Re Zero kara Hajimeru Isekai Seikatsu 4th season - 02 (AT-X 1440x1080 MPEG2 AAC).srt',
      ),
      'Re Zero kara Hajimeru Isekai Seikatsu 4th season - 02',
    );
  });

  test('dotted scene names', () {
    expect(
      displayName('Show.Name.S01E02.1080p.WEB-DL.x264.mkv'),
      'Show Name S01E02',
    );
  });

  test('plain and Japanese names are kept', () {
    expect(displayName('kotohori_sample.mp4'), 'kotohori sample');
    expect(displayName('ぼっち・ざ・ろっく！ 第1話.mkv'), 'ぼっち・ざ・ろっく！ 第1話');
    expect(displayName('[Group] [1080p].mkv'), '[Group] [1080p]');
  });
}
