import 'package:build/build.dart';
import 'package:glob/glob.dart';

import 'crawler.dart';
import 'generator.dart';

Builder createBuilder(BuilderOptions options) {
  return LicenseCollectingBuilder(
    outputPath: options.config['output'] as String,
    entrypoints: Glob(options.config['entrypoints'] as String),
  );
}

class LicenseCollectingBuilder extends Builder {
  final String outputPath;
  final Glob entrypoints;

  LicenseCollectingBuilder(
      {required this.outputPath, required this.entrypoints});

  @override
  Future<void> build(BuildStep buildStep) async {
    final crawler = LicenseCrawler.forStep(buildStep);
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
