import 'package:build/build.dart';
import 'package:graphs/graphs.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

class LicenseCrawler {
  final AssetReader reader;
  final String rootPackage;

  LicenseCrawler(this.reader, this.rootPackage);

  factory LicenseCrawler.forStep(BuildStep step) {
    return LicenseCrawler(step, step.inputId.package);
  }

  Future<Map<String, String>> collectLicenses(
      {bool includeDevDependencies = false}) async {
    final transitiveDeps = crawlAsync<String, Pubspec>(
      [rootPackage],
      pubspecOf,
      (package, pubspec) {
        return [
          // Crawl dependencies
          ...pubspec.dependencies.keys,
          // If desired, also include dev dependencies of the root package
          if (package == rootPackage && includeDevDependencies)
            ...pubspec.devDependencies.keys,
        ];
      },
    ).map((pubspec) => pubspec.name);

    return {
      await for (final package in transitiveDeps)
        package: await licenseOf(package)
    };
  }

  Future<Pubspec> pubspecOf(String package) async {
    final id = AssetId(package, 'pubspec.yaml');
    try {
      final rawContent = await reader.readAsString(id);
      return Pubspec.parse(rawContent);
    } on AssetNotFoundException catch (e) {
      log.warning('It seems like $package does not have a pubspec?! $e');
      return Pubspec(package);
    }
  }

  Future<String> licenseOf(String package) async {
    for (final files in ['LICENSE', 'LICENSE.md', 'LICENSE.txt']) {
      final licenseId = AssetId(package, files);

      if (await reader.canRead(licenseId)) {
        return reader.readAsString(licenseId);
      }
    }

    log.warning('Could not find a license for package $package.');
    return 'unknown license';
  }
}
