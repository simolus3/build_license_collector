import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'crawler.dart';
import 'generator.dart';

Builder createBuilder(BuilderOptions options) {
  return LicenseCollectingBuilder(
    outputPath: options.config['output'] as String,
    entrypoints: Glob(options.config['entrypoints'] as String),
    dartLibraries: (options.config['dart'] as List).cast(),
  );
}

class LicenseCollectingBuilder extends Builder {
  final String outputPath;
  final Glob entrypoints;

  /// Platform-specific libraries assumed to be available (e.g. `js_interop`).
  final List<String> dartLibraries;

  LicenseCollectingBuilder({
    required this.outputPath,
    required this.entrypoints,
    required this.dartLibraries,
  });

  @override
  Future<void> build(BuildStep buildStep) async {
    final crawler = LicenseCrawler.forStep(buildStep, dartLibraries);
    final licenseByPackage = await crawler.collectLicenses(entrypoints);

    final outputId = buildStep.allowedOutputs.single;
    String output;
    if (outputId.extension == '.json') {
      output = writeLicencesJson(licenseByPackage);
    } else {
      output = writeLicensesDart(licenseByPackage);
    }

    await buildStep.writeAsString(outputId, output);
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      r'$package$': [outputPath]
    };
  }
}
