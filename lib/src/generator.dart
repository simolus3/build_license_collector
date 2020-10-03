import 'package:dart_style/dart_style.dart';

final _dartfmt = DartFormatter();

String writeLicenses(Map<String, String> licenses) {
  final buffer = StringBuffer('// Auto-generated. Do not edit by hand \n');

  // Write a constant for each unique license in licenses.values
  final licenseTextToIndex = <String, int>{};
  var index = 0;

  String getterForIndex(int index) => '_license$index';

  for (final license in licenses.values) {
    if (!licenseTextToIndex.containsKey(license)) {
      final indexForLicense = index++;

      licenseTextToIndex[license] = indexForLicense;
      buffer.write('const String ${getterForIndex(indexForLicense)} = ');
      license.writeExpandedStringLiteral(buffer);
      buffer.write(';\n');
    }
  }

  buffer.write('const licenses = <String, String>{');
  for (final packageAndLicense in licenses.entries) {
    final package = packageAndLicense.key;
    final license = packageAndLicense.value;

    package.writeStringLiteral(buffer);
    buffer.write(': ${getterForIndex(licenseTextToIndex[license])},');
  }
  buffer.write('};');

  return _dartfmt.format(buffer.toString());
}

extension on String {
  void writeStringLiteral(StringBuffer into) {
    into..write("r'")..write(replaceAll('\n', r'\n'))..write("'");
  }

  void writeExpandedStringLiteral(StringBuffer into) {
    into
      ..writeln("'''")
      ..write(this)
      ..writeln("'''");
  }
}
