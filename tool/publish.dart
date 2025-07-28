import 'package:simons_pub_uploader/upload.dart';

void main() async {
  uploadPackages([
    await FileSystemPackage.load(
      directory: '.',
      listPackageFiles: (fs) async* {
        final root = fs.currentDirectory;

        yield* root.childDirectory('lib').list(recursive: true);
        yield root.childFile('build.yaml');
        yield root.childFile('LICENSE');
      },
    )
  ]);
}
