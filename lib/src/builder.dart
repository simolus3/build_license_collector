import 'package:build/build.dart';

import 'crawler.dart';
import 'generator.dart';

Builder createBuilder(BuilderOptions options) {
  const key = 'include_dev_dependencies';
  if (options.config.containsKey(key)) {
    return LicenseCollectingBuilder(options.config[key] as bool);
  } else {
    return LicenseCollectingBuilder();
  }
}

class LicenseCollectingBuilder extends Builder {
  final bool includeDevDependencies;

  LicenseCollectingBuilder([this.includeDevDependencies = false]);

  @override
  Future<void> build(BuildStep buildStep) async {
    final crawler = LicenseCrawler.forStep(buildStep);
    final licenseByPackage = await crawler.collectLicenses(
        includeDevDependencies: includeDevDependencies);

    final output = writeLicenses(licenseByPackage);
    final outputId = AssetId(crawler.rootPackage, 'lib/licenses.g.dart');
    await buildStep.writeAsString(outputId, output);
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['licenses.g.dart']
    };
  }
}
