import 'dart:io';

void main(List<String> args) {
  final lcovPath = args.isNotEmpty ? args.first : 'coverage/lcov.info';
  final lcovFile = File(lcovPath);

  if (!lcovFile.existsSync()) {
    stderr.writeln('Coverage file not found: $lcovPath');
    exitCode = 1;
    return;
  }

  final thresholds = <String, double>{
    'lib/auth/auth_service.dart': 0.80,
    'lib/auth/auth_gate.dart': 0.80,
    'lib/mqtt/mqtt_service.dart': 0.80,
    'lib/view_models/home_view_model.dart': 0.80,
    'lib/view_models/profile_view_model.dart': 0.80,
  };

  final coverageByFile = _parseLcov(lcovFile.readAsLinesSync());
  var failed = false;

  for (final entry in thresholds.entries) {
    final normalizedPath = _normalizePath(entry.key);
    final coverage = coverageByFile[normalizedPath];

    if (coverage == null) {
      stderr.writeln('Missing coverage record for ${entry.key}');
      failed = true;
      continue;
    }

    final percentage = (coverage * 100).toStringAsFixed(2);
    final expected = (entry.value * 100).toStringAsFixed(0);
    stdout.writeln('${entry.key}: $percentage% (required >= $expected%)');

    if (coverage < entry.value) {
      failed = true;
      stderr.writeln('Coverage check failed for ${entry.key}.');
    }
  }

  if (failed) {
    exitCode = 1;
    return;
  }

  stdout.writeln('Coverage gate passed.');
}

Map<String, double> _parseLcov(List<String> lines) {
  final result = <String, double>{};
  String? currentFile;
  int? linesFound;
  int? linesHit;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = _normalizePath(line.substring(3));
      linesFound = null;
      linesHit = null;
      continue;
    }

    if (line.startsWith('LF:')) {
      linesFound = int.tryParse(line.substring(3));
      continue;
    }

    if (line.startsWith('LH:')) {
      linesHit = int.tryParse(line.substring(3));
      continue;
    }

    if (line == 'end_of_record' &&
        currentFile != null &&
        linesFound != null &&
        linesHit != null &&
        linesFound > 0) {
      result[currentFile] = linesHit / linesFound;
      currentFile = null;
      linesFound = null;
      linesHit = null;
    }
  }

  return result;
}

String _normalizePath(String path) => path.replaceAll('\\', '/');
