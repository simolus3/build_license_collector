import 'package:build/build.dart';
import 'package:pub_semver/pub_semver.dart';

import 'crawler.dart';
import 'generator.dart';

Builder createBuilder(BuilderOptions options) {
  return LicenseCollectingBuilder(
    includeDevDependencies: options.config['include_dev_dependencies'] as bool,
    outputPath: options.config['output'] as String,
  );
}

class LicenseCollectingBuilder extends Builder {
  final bool includeDevDependencies;
  final String outputPath;

  LicenseCollectingBuilder(
      {required this.includeDevDependencies, required this.outputPath});

  @override
  Future<void> build(BuildStep buildStep) async {
    final crawler = LicenseCrawler.forStep(buildStep);
    final licenseByPackage = await crawler.collectLicenses(
        includeDevDependencies: includeDevDependencies);

    final outputId = buildStep.allowedOutputs.single;
    String output;
    if (outputId.extension == '.json') {
      output = writeLicencesJson(licenseByPackage);
    } else {
      final packageConfig = await buildStep.packageConfig;
      final languageVersion = packageConfig.packages
          .singleWhere((e) => e.name == buildStep.inputId.package)
          .languageVersion;

      output = writeLicensesDart(
        licenseByPackage,
        languageVersion: Version(
            languageVersion?.major ?? 3, languageVersion?.minor ?? 6, 0),
      );
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
