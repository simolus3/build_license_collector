import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:cli_util/cli_util.dart';
import 'package:glob/glob.dart';
import 'package:graphs/graphs.dart';
import 'package:path/path.dart' as p;

/// Uses information emitted by `build_modules` to crawl the import graph of a
/// Dart program and collect licenses from imported packages and the SDK.
class LicenseCrawler {
  final AssetReader reader;
  final List<String> availableDartLibraries;

  LicenseCrawler(this.reader, this.availableDartLibraries);

  factory LicenseCrawler.forStep(
      BuildStep step, List<String> availableDartLibraries) {
    return LicenseCrawler(step, availableDartLibraries);
  }

  Future<ModuleLibrary?> _libraryForSource(AssetId id) async {
    String read;
    try {
      read =
          await reader.readAsString(id.changeExtension(moduleLibraryExtension));
    } on AssetNotFoundException {
      return null;
    }

    return ModuleLibrary.deserialize(id, read);
  }

  Iterable<AssetId> _dependencies(ModuleLibrary library) sync* {
    yield* library.deps;
    outer:
    for (final conditional in library.conditionalDeps) {
      for (final available in availableDartLibraries) {
        if (conditional['dart.library.$available'] case final import?) {
          yield import;
          continue outer;
        }
      }

      if (conditional[r'$default'] case final defaultImport?) {
        yield defaultImport;
      }
    }
  }

  Future<Map<String, String>> collectLicenses(Glob entrypoints) async {
    final found = await reader.findAssets(entrypoints).toList();
    final modules = crawlAsync<AssetId, ModuleLibrary?>(
      found,
      _libraryForSource,
      (id, library) {
        if (library == null) {
          return const [];
        }
        return _dependencies(library);
      },
    );

    final packages = {
      r'$sdk',
      await for (final importedModule in modules)
        if (importedModule != null) importedModule.source.package
    };

    return {for (final package in packages) package: await licenseOf(package)};
  }

  Future<String> licenseOf(String package) async {
    if (package == r'$sdk') {
      // We can use raw dart:io APIs here to read the license file since an SDK
      // change invalidates the entire build.
      final root = sdkPath;
      return File(p.join(root, 'LICENSE')).readAsString();
    }

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

final class ModuleLibrary {
  final AssetId source;

  /// The IDs of libraries that are imported or exported by this library.
  final List<AssetId> deps;

  /// Deps that are imported with a conditional import.
  ///
  /// Keys are the stringified ast node for the conditional, and the default
  /// import is under the magic `$default` key.
  final List<Map<String, AssetId>> conditionalDeps;

  ModuleLibrary(
      {required this.source,
      required this.deps,
      required this.conditionalDeps});

  factory ModuleLibrary.deserialize(AssetId source, String encoded) {
    final json = jsonDecode(encoded) as Map<String, Object?>;

    return ModuleLibrary(
      source: source,
      deps: _deserializeAssetIds(json['deps'] as Iterable),
      conditionalDeps: (json['conditionalDeps'] as Iterable).map((conditions) {
        return Map.of(
          (conditions as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, AssetId.parse(v as String)),
          ),
        );
      }).toList(),
    );
  }

  static List<AssetId> _deserializeAssetIds(Iterable<Object?> serlialized) =>
      serlialized.map((decoded) => AssetId.parse(decoded as String)).toList();
}
