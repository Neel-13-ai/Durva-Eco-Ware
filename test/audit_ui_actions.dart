import 'dart:io';

void main() {
  final libDir = Directory('c:/workspace/durvaeco/lib');
  final dartFiles = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')).toList();
  
  final repos = dartFiles.where((f) => f.path.contains('repositories') || (f.path.contains('data') && f.path.endsWith('_repository.dart'))).toList();
  final uiFiles = dartFiles.where((f) => f.path.contains('presentation') || f.path.contains('controllers') || f.path.contains('providers')).toList();
  
  // Exclude repo files from UI search
  final uiContent = uiFiles.map((f) => f.readAsStringSync()).join('\n');

  print('Total UI/Controller/Provider files: ${uiFiles.length}');
  print('Total Repositories: ${repos.length}');

  // Match: Future<...> methodName(
  final methodRegex = RegExp(r'Future<[\s\S]*?>\s+([a-zA-Z0-9_]+)\s*\(', multiLine: true);

  final uncalledMethods = <String, List<String>>{};
  final calledMethods = <String, List<String>>{};
  int totalMethods = 0;
  int uncalledCount = 0;

  for (final repo in repos) {
    final content = repo.readAsStringSync();
    final repoName = repo.path.split(Platform.pathSeparator).last;
    final matches = methodRegex.allMatches(content);
    for (final m in matches) {
      final methodName = m.group(1)!;
      if (methodName == 'call' || methodName == 'dispose' || methodName == 'copyWith' || methodName.startsWith('_')) continue;
      
      totalMethods++;
      
      // Check if methodName is called in UI/Controller/Provider
      final callPattern = RegExp(r'\b' + methodName + r'\s*\(');
      // count matches in uiContent
      final count = callPattern.allMatches(uiContent).length;
      
      if (count == 0) {
        uncalledMethods.putIfAbsent(repoName, () => []).add(methodName);
        uncalledCount++;
      } else {
        calledMethods.putIfAbsent(repoName, () => []).add(methodName);
      }
    }
  }

  print('\n================================================================');
  print('          UI ACTION & REPOSITORY INTEGRATION AUDIT              ');
  print('================================================================');
  print('Total Repository CRUD Methods: $totalMethods');
  print('Directly Hooked in UI / Controllers / Providers: ${totalMethods - uncalledCount}');
  print('NOT Directly Invoked in UI (Missing UI Button/Trigger): $uncalledCount');
  print('----------------------------------------------------------------');
  
  if (uncalledCount > 0) {
    print('\nDetailed List of APIs/Methods without Direct UI Trigger:');
    uncalledMethods.forEach((repo, methods) {
      print('\n📁 $repo:');
      for (final m in methods) {
        print('   ⚠️  $m()');
      }
    });
  } else {
    print('\n🎉 All repository methods are actively hooked up into UI screens/controllers!');
  }
}
