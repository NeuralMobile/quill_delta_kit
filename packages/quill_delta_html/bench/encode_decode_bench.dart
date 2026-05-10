import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:quill_delta_html/quill_delta_html.dart';

/// Run with: dart run bench/encode_decode_bench.dart
void main() {
  EncodeSmall().report();
  EncodeMedium().report();
  EncodeLarge().report();
  DecodeSmall().report();
  DecodeMedium().report();
  DecodeLarge().report();
  RoundTripMedium().report();
}

final _codec = QuillHtmlCodec();

Delta _smallDelta() {
  return Delta()
    ..insert('Hello ')
    ..insert('world', {'bold': true})
    ..insert('!\n');
}

Delta _mediumDelta() {
  final d = Delta();
  for (var i = 0; i < 50; i++) {
    d.insert('Heading $i', {});
    d.insert('\n', {'header': (i % 3) + 1});
    d.insert('Paragraph $i with ');
    d.insert('bold', {'bold': true});
    d.insert(' and ');
    d.insert('italic', {'italic': true});
    d.insert(' and ');
    d.insert('https://example.com', {'link': 'https://example.com'});
    d.insert(' inline.\n');
    d.insert('item one');
    d.insert('\n', {'list': 'bullet'});
    d.insert('item two');
    d.insert('\n', {'list': 'bullet', 'indent': 1});
  }
  return d;
}

Delta _largeDelta() {
  final d = Delta();
  for (var i = 0; i < 500; i++) {
    d.insert('Word $i ');
    if (i % 5 == 0) {
      d.insert('emphasized ', {'italic': true, 'color': '#ff0000'});
    }
    if (i % 10 == 0) {
      d.insert('\n', {'header': 2});
    } else if (i % 7 == 0) {
      d.insert('\n', {'list': 'ordered', 'indent': i % 3});
    } else {
      d.insert('\n');
    }
  }
  return d;
}

final _smallHtml = _codec.encode(_smallDelta());
final _mediumHtml = _codec.encode(_mediumDelta());
final _largeHtml = _codec.encode(_largeDelta());

class EncodeSmall extends BenchmarkBase {
  EncodeSmall() : super('encode.small');
  final delta = _smallDelta();
  @override
  void run() => _codec.encode(delta);
}

class EncodeMedium extends BenchmarkBase {
  EncodeMedium() : super('encode.medium');
  final delta = _mediumDelta();
  @override
  void run() => _codec.encode(delta);
}

class EncodeLarge extends BenchmarkBase {
  EncodeLarge() : super('encode.large');
  final delta = _largeDelta();
  @override
  void run() => _codec.encode(delta);
}

class DecodeSmall extends BenchmarkBase {
  DecodeSmall() : super('decode.small');
  @override
  void run() => _codec.decode(_smallHtml);
}

class DecodeMedium extends BenchmarkBase {
  DecodeMedium() : super('decode.medium');
  @override
  void run() => _codec.decode(_mediumHtml);
}

class DecodeLarge extends BenchmarkBase {
  DecodeLarge() : super('decode.large');
  @override
  void run() => _codec.decode(_largeHtml);
}

class RoundTripMedium extends BenchmarkBase {
  RoundTripMedium() : super('roundtrip.medium');
  final delta = _mediumDelta();
  @override
  void run() => _codec.decode(_codec.encode(delta));
}
