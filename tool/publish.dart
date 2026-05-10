// Helper that prepares a single package for `dart pub publish`.
//
// Workspace pubspecs use `path:` dependencies to other packages in the
// monorepo; pub blocks publishing those. This script:
//   1. Reads the target package's pubspec.yaml.
//   2. For every `dependency` whose value is `path: ../X`, replaces it with
//      the caret constraint derived from that package's published version.
//   3. Removes the `resolution: workspace` line.
//   4. Writes the rewritten pubspec to <pkg>/pubspec.publish.yaml.
//   5. Prints next-step instructions.
//
// Usage:
//   dart run tool/publish.dart <package-name>            # prepare
//   dart run tool/publish.dart <package-name> --apply    # overwrite pubspec.yaml
//   dart run tool/publish.dart <package-name> --restore  # restore from .bak
//
// Recommended publish flow (run from repo root):
//   dart run tool/publish.dart quill_delta_core --apply
//   cd packages/quill_delta_core && dart pub publish --dry-run
//   # if happy:
//   dart pub publish
//   cd ../..
//   dart run tool/publish.dart quill_delta_core --restore
//
// Repeat in dependency order: core → html → markdown → docx → pdf.

import 'dart:io';

const _packagesDir = 'packages';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(_usage);
    exit(64);
  }
  final pkgName = args[0];
  final apply = args.contains('--apply');
  final restore = args.contains('--restore');

  final pkgDir = Directory('$_packagesDir/$pkgName');
  if (!pkgDir.existsSync()) {
    stderr.writeln('Package not found: ${pkgDir.path}');
    exit(66);
  }
  final pubspec = File('${pkgDir.path}/pubspec.yaml');
  final backup = File('${pkgDir.path}/pubspec.yaml.bak');

  if (restore) {
    if (!backup.existsSync()) {
      stderr.writeln('No backup at ${backup.path}; nothing to restore.');
      exit(0);
    }
    pubspec.writeAsStringSync(backup.readAsStringSync());
    backup.deleteSync();
    stdout.writeln('Restored ${pubspec.path} from backup.');
    return;
  }

  final original = pubspec.readAsStringSync();
  final rewritten = _rewrite(original, pkgName);

  if (apply) {
    backup.writeAsStringSync(original);
    pubspec.writeAsStringSync(rewritten);
    stdout.writeln('Wrote publish-ready pubspec to ${pubspec.path}.');
    stdout.writeln('Backup at ${backup.path}.');
    stdout.writeln('Run: cd ${pkgDir.path} && dart pub publish --dry-run');
    stdout.writeln(
        'When done: dart run tool/publish.dart $pkgName --restore');
  } else {
    final preview = File('${pkgDir.path}/pubspec.publish.yaml');
    preview.writeAsStringSync(rewritten);
    stdout.writeln('Preview written to ${preview.path}');
    stdout.writeln('Re-run with --apply to swap pubspec.yaml in place.');
  }
}

String _rewrite(String pubspec, String selfName) {
  final lines = pubspec.split('\n');
  final out = <String>[];
  String? pendingDepName;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Drop the workspace resolution directive — published packages don't
    // resolve through the parent.
    if (trimmed == 'resolution: workspace') continue;

    // Detect "<dep>:" line that starts a multi-line `path:` block.
    final depMatch =
        RegExp(r'^(\s+)([a-z_][a-z0-9_]*):\s*$').firstMatch(line);
    if (depMatch != null) {
      pendingDepName = depMatch.group(2);
      // Peek next line for `path: ...`.
      if (i + 1 < lines.length) {
        final next = lines[i + 1];
        final pathMatch = RegExp(r'^\s+path:\s*\.\./([a-z_][a-z0-9_]*)\s*$')
            .firstMatch(next);
        if (pathMatch != null) {
          final depPkg = pathMatch.group(1)!;
          final version = _readVersion(depPkg);
          if (version != null) {
            // Emit "<dep>: ^X.Y.Z" inline; skip both source lines.
            out.add('${depMatch.group(1)}$pendingDepName: ^$version');
            i++; // skip path: line
            continue;
          }
        }
      }
    }
    out.add(line);
  }
  return out.join('\n');
}

String? _readVersion(String pkg) {
  final f = File('$_packagesDir/$pkg/pubspec.yaml');
  if (!f.existsSync()) return null;
  for (final line in f.readAsLinesSync()) {
    final m = RegExp(r'^version:\s*(\S+)\s*$').firstMatch(line);
    if (m != null) return m.group(1);
  }
  return null;
}

const String _usage = '''
Usage:
  dart run tool/publish.dart <package> [--apply | --restore]

Without flags: writes a preview pubspec.publish.yaml beside the package's
pubspec.yaml so you can diff before applying.

--apply   Backup pubspec.yaml -> pubspec.yaml.bak and overwrite with the
          publish-ready version (path deps replaced, resolution removed).
--restore Restore pubspec.yaml from pubspec.yaml.bak.

Run from the repository root.
''';
