import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (input.userDefines['build_assets'] == false) {
      stdout.writeln('Skipping the Rust build: user-define build_assets=false');
      return;
    }
    await FlutterRustBridgeNativeAssetsBuilder(
      cratePath: 'rust',
      extraCargoEnvironmentVariables: _bindgenEnvironment(input),
    ).run(input: input, output: output);
  });
}

// rquickjs runs bindgen on Android, which must load the NDK's libclang; Linux
// NDKs before r26 keep it under lib64, later ones and every macOS NDK under lib.
Map<String, String> _bindgenEnvironment(BuildInput input) {
  if (!input.config.buildCodeAssets ||
      input.config.code.targetOS != OS.android) {
    return const {};
  }
  final compiler = input.config.code.cCompiler?.compiler;
  if (compiler == null) {
    return const {};
  }
  final llvmRoot = File.fromUri(compiler).parent.parent;
  final libclangDir =
      _findLibclangDir(llvmRoot) ?? _findLibclangInSiblingNdks(llvmRoot);
  if (libclangDir != null) {
    return {'LIBCLANG_PATH': libclangDir};
  }
  throw StateError(
    'No libclang under ${llvmRoot.path} (lib or lib64), and none of its '
    'sibling NDK installs have one either; the NDK Flutter passed cannot '
    'run bindgen for rquickjs',
  );
}

String? _findLibclangDir(Directory llvmRoot) {
  for (final name in const ['lib', 'lib64']) {
    final directory = Directory(
      '${llvmRoot.path}${Platform.pathSeparator}$name',
    );
    if (directory.existsSync() && directory.listSync().any(_isLibclang)) {
      return directory.path;
    }
  }
  return null;
}

// NDK r27 dropped libclang to save space; r28 brought it back. Flutter's
// native-assets NDK auto-selection doesn't always agree with the NDK version
// android.ndkVersion pins for the rest of the build, so when the NDK it
// picked lacks libclang, look for a sibling NDK install (CI machines and the
// Android SDK commonly keep several side by side) that has one.
String? _findLibclangInSiblingNdks(Directory llvmRoot) {
  // llvmRoot is <ndkRoot>/<version>/toolchains/llvm/prebuilt/<host>.
  final segments = llvmRoot.path
      .split(Platform.pathSeparator)
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.length < 5) {
    return null;
  }
  final host = segments.last;
  final ndkVersionDir = llvmRoot.parent.parent.parent.parent;
  final ndkRoot = ndkVersionDir.parent;
  if (!ndkRoot.existsSync()) {
    return null;
  }
  for (final entry in ndkRoot.listSync()) {
    if (entry is! Directory || entry.path == ndkVersionDir.path) {
      continue;
    }
    final candidate = Directory(
      [
        entry.path,
        'toolchains',
        'llvm',
        'prebuilt',
        host,
      ].join(Platform.pathSeparator),
    );
    if (!candidate.existsSync()) {
      continue;
    }
    final found = _findLibclangDir(candidate);
    if (found != null) {
      return found;
    }
  }
  return null;
}

bool _isLibclang(FileSystemEntity entity) {
  return entity.path.split(Platform.pathSeparator).last.startsWith('libclang.');
}
