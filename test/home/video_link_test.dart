import 'package:flutter_test/flutter_test.dart';
import 'package:kotohori/features/home/video_link.dart';

void main() {
  checks();
  test('only http(s) links with a host count', () {
    expect(
      parseVideoLink('  https://a.com/x.mp4 '),
      Uri.parse('https://a.com/x.mp4'),
    );
    expect(parseVideoLink('http://192.168.1.5:8000/ep.mkv'), isNotNull);
    for (final bad in [
      '',
      'ep01.mp4',
      'content://x/y',
      'ftp://a.com/x',
      'https://',
    ]) {
      expect(parseVideoLink(bad), isNull, reason: bad);
    }
    expect(isVideoLink('https://a.com/x.mp4'), isTrue);
    expect(isVideoLink('content://media/1'), isFalse);
  });

  test('names a link like a file', () {
    String name(String s) => videoLinkName(Uri.parse(s));
    expect(
      name('https://a.com/anime/Show%20-%2002.mkv?token=1'),
      'Show - 02.mkv',
    );
    expect(name('https://a.com/show-02/index.m3u8'), 'show-02');
    expect(name('https://a.com/master.m3u8'), 'a.com');
    expect(name('https://a.com/'), 'a.com');
  });
}

void checks() {
  test(
    'a web page or an error is refused; a video or anything unknown passes',
    () {
      final bytes = 'ftypisom'.codeUnits;
      expect(looksLikeVideo(206, 'video/mp4', bytes), isTrue);
      expect(looksLikeVideo(200, 'application/octet-stream', bytes), isTrue);
      expect(
        looksLikeVideo(
          200,
          'application/vnd.apple.mpegurl',
          '#EXTM3U'.codeUnits,
        ),
        isTrue,
      );
      expect(looksLikeVideo(200, null, bytes), isTrue);
      expect(looksLikeVideo(200, 'text/html; charset=utf-8', bytes), isFalse);
      expect(
        looksLikeVideo(200, 'text/plain', '  <!DOCTYPE html>'.codeUnits),
        isFalse,
      );
      for (final status in [403, 404, 500, 0]) {
        expect(
          looksLikeVideo(status, 'video/mp4', bytes),
          isFalse,
          reason: '$status',
        );
      }
    },
  );

  test('Google Drive share links become direct links', () {
    const direct =
        'https://drive.usercontent.google.com/download?id=1SFxo8rvYialKjxsmZF6q580xE0eg2gcg&export=download&confirm=t';
    for (final share in [
      'https://drive.google.com/file/d/1SFxo8rvYialKjxsmZF6q580xE0eg2gcg/view?usp=sharing',
      ' https://drive.google.com/file/d/1SFxo8rvYialKjxsmZF6q580xE0eg2gcg/view ',
      'https://drive.google.com/open?id=1SFxo8rvYialKjxsmZF6q580xE0eg2gcg',
      'https://drive.google.com/uc?export=download&id=1SFxo8rvYialKjxsmZF6q580xE0eg2gcg',
    ]) {
      expect(parseVideoLink(share).toString(), direct, reason: share);
    }
    // Not a file: left alone (and refused when checked).
    expect(
      parseVideoLink('https://drive.google.com/drive/folders/abc').toString(),
      'https://drive.google.com/drive/folders/abc',
    );
  });

  test('file name from Content-Disposition', () {
    expect(fileNameFrom('attachment; filename="NO2026.MP4"'), 'NO2026.MP4');
    expect(
      fileNameFrom("attachment; filename*=UTF-8''%E7%AC%AC1%E8%A9%B1.mkv"),
      '第1話.mkv',
    );
    expect(fileNameFrom('inline'), isNull);
    expect(fileNameFrom(null), isNull);
  });
}
