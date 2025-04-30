import 'dart:io';

void main() async {
  // Start in the lib directory
  final libDir = Directory('lib');
  
  if (!libDir.existsSync()) {
    print('Error: lib directory not found');
    return;
  }
  
  int filesFixed = 0;
  
  await for (var entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      
      if (content.contains("import 'package:Stash/")) {
        final newContent = content.replaceAll(
          "import 'package:Stash/",
          "import 'package:LoyaltyWallet/"
        );
        
        await entity.writeAsString(newContent);
        print('Fixed imports in: ${entity.path}');
        filesFixed++;
      }
    }
  }
  
  print('Fixed imports in $filesFixed files');
} 