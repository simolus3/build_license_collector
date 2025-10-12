import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_license_collector/builder.dart';
import 'package:build_modules/builders.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  test('generates SDK dependency', () async {
    await testBuilders(
      [
        moduleLibraryBuilder(BuilderOptions({})),
        _licenseBuilder(),
      ],
      {},
      rootPackage: 'a',
      outputs: {
        'a|lib/src/licenses.g.dart': decodedMatches(
            contains('Copyright 2012, the Dart project authors.'))
      },
    );
  });

  test('can generate json', () async {
    await testBuilders(
      [
        moduleLibraryBuilder(BuilderOptions({})),
        _licenseBuilder(output: 'web/licenses.json'),
      ],
      {},
      rootPackage: 'a',
      outputs: {'a|web/licenses.json': anything},
    );
  });

  test('crawls dependencies', () async {
    final result = await testBuilders(
      [
        moduleLibraryBuilder(BuilderOptions({})),
        _licenseBuilder(output: 'web/licenses.json'),
      ],
      {
        'a|web/a.dart': "import 'package:b/b.dart';",
        'b|lib/b.dart': "import 'package:c/c.dart';",
        'b|LICENSE': "B LICENSE",
        'c|lib/c.dart': "",
        'c|LICENSE': "C LICENSE",
      },
      rootPackage: 'a',
    );

    final output = json.decode(result.readerWriter.testing.readString(
        makeAssetId('a|.dart_tool/build/generated/a/web/licenses.json')));
    expect(output['packages'].keys, unorderedEquals([r'$sdk', 'a', 'b', 'c']));
  });
}

Builder _licenseBuilder(
    {String output = 'lib/src/licenses.g.dart',
    String entrypoints = 'web/*.dart'}) {
  return createBuilder(BuilderOptions({
    'output': output,
    'entrypoints': entrypoints,
  }));
}
