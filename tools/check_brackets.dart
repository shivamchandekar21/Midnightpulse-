import 'dart:io';

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'lib/screens/home_screen.dart';
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('File not found: $path');
    exit(2);
  }
  final content = file.readAsStringSync();
  final pairs = {
    '(': ')',
    '{': '}',
    '[': ']',
  };
  for (final entry in pairs.entries) {
    final open = RegExp(RegExp.escape(entry.key)).allMatches(content).length;
    final close = RegExp(RegExp.escape(entry.value)).allMatches(content).length;
    print('${entry.key} -> $open   ${entry.value} -> $close');
  }
}
