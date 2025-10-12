A [builder](https://pub.dev/packages/build) collecting license information from your dependencies.

## Usage

To use this package, add a dependency on it (and `build_runner`, if you don't depend on that already):

```shell
dart pub add dev:build_license_collector dev:build_runner
```

After running `dart pub run build_runner build`, you'll have a `licenses.g.dart` file in your app's
`lib/src` directory.

## Configuration

By default, the license collector starts crawling packages transitively imported from any file
in the `web/` directory of your project.

The set of entrypoints considered can be changed with builder options:

```yaml
targets:
  $default:
    builders:
      build_license_collector:
        entrypoints: lib/main.dart # glob syntax supported here
```

You can also change the path of the generated file:

```yaml
targets:
  $default:
    builders:
      build_license_collector:
        output: lib/src/all_licenses.g.dart
```

This package can also emit a JSON structure when the output extension is `.json`.
The generated structure looks like this, with the entries in `packages` pointing
to a text index in `texts`.

```json
{
  "texts": [
    "license for pgk foo and pkg baz",
    "license for bar",
  ],
  "packages": {
    "foo": 0,
    "bar": 1,
    "baz": 0,
  }
}
```

When resolving imports, the package needs to know how to interpret conditional or
platform-specific imports. By default, it assumes a compilation to the web.
This can be changed with the `dart` option:

```yaml
targets:
  $default:
    builders:
      build_license_collector:
        dart: [async, core, ffi, typed_data, io]
```
