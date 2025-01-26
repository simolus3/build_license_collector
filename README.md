A [builder](https://pub.dev/packages/build) collecting license information from your dependencies.

## Usage

Thanks to [Dart's build system](https://pub.dev/packages/build_runner), using this package couldn't be
any simpler. Just add this package and `build_runner` to your `dev_dependencies` and you're good to go:

```yaml
dev_dependencies:
  build_license_collector: ^1.0.0
  build_runner: ^2.4.0
```

After running `dart pub run build_runner build`, you'll have a `licenses.g.dart` file in your app's
`lib/` directory.

## Configuration

By default, license collection will happen across your regular `dependencies` since that's the code
you usually ship to users. If you want to, you can also include licenses of `dev_dependencies`.
To configure this builder, create a `build.yaml` next to your pubspec. It should have the following
content:

```yaml
targets:
  $default:
    builders:
      build_license_collector:
        include_dev_dependencies: true
```

You can also change the path of the generated file:

```yaml
targets:
  $default:
    builders:
      build_license_collector:
        output: lib/src/licenses.g.dart
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
