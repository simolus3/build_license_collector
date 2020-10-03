[![extra_pedantic on pub.dev](https://img.shields.io/badge/style-extra__pedantic-blue)](https://pub.dev/packages/extra_pedantic)

A [builder](https://pub.dev/packages/build) collecting license information from your dependencies.

## Usage

Thanks to [Dart's build system](https://pub.dev/packages/build_runner), using this package couldn't be
any simpler. Just add this package and `build_runner` to your `dev_dependencies` and you're good to go:

```yaml
dev_dependencies:
  build_license_collector: ^1.0.0
  build_runner: ^1.10.3
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
