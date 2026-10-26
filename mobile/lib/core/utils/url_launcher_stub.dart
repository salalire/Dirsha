import 'dart:io' show Platform, Process;

void openUrlInNewTab(String url) {
  // Unit tests run in a headless fake timer environment; avoid spawning OS processes.
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return;
  }
  try {
    if (Platform.isLinux) {
      Process.run('xdg-open', [url]);
    } else if (Platform.isMacOS) {
      Process.run('open', [url]);
    } else if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', url]);
    }
  } catch (_) {
    // Graceful no-op on platforms without command-line launcher
  }
}
