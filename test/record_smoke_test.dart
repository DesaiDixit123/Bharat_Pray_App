import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

void main() {
  test('Verify AudioRecorder instantiates', () {
    final recorder = AudioRecorder();
    expect(recorder, isNotNull);
  });
}
