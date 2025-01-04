import 'dart:io';

void generate(String? path) => _execute(path);

String _toCamelCase(String input) {
  List<String> parts = input.split('_');
  if (input.contains('-')) {
    parts = input.split('-');
  }

  final fixedParts = parts.map((part) {
    String safePart = part;
    if (part.contains('_')) {
      safePart = _toUpperCamelCase(part);
      return safePart;
    }
    return part[0].toUpperCase() + part.substring(1);
  });

  final partString = fixedParts.join();

  return partString[0].toLowerCase() + partString.substring(1);
}

String _toUpperCamelCase(String input) {
  List<String> parts = input.split('_');
  if (input.contains('-')) {
    parts = input.split('-');
  }

  final fixedParts = parts.map((part) {
    String safePart = part;
    if (part.contains('_')) {
      safePart = _toUpperCamelCase(part);
      return safePart;
    }
    return part[0].toUpperCase() + part.substring(1);
  });

  return fixedParts.join();
}

void _execute(String? path) {
  try {
    print('Generating assets Dart code...');

    Directory assetsDir = Directory('assets/');
    List<FileSystemEntity> assets = assetsDir.listSync(recursive: true);
    Map<String, List<String>> propertiesMap = {};
    Map<String, List<String>> staticsMap = {};
    String dartCode = '';
    List<String> baseClassStatics = [];

    for (var asset in assets) {
      if (asset is File) {
        if (asset.path.contains('.DS_Store')) {
          continue;
        }
        if (asset.path.contains('.gitkeep')) {
          continue;
        }
        if (asset.path.contains('/fonts/')) {
          continue;
        }
        if (asset.path.contains('/translations/')) {
          continue;
        }

        // retrieve the filename
        final String assetName = asset.path.split('/').last;
        final String assetFolder = asset.path
            .replaceAll(assetName, '')
            .replaceAll('../', '')
            .replaceAll('.', '');

        final paths = assetFolder.split('/')
          ..removeWhere((element) => element.isEmpty || element == 'assets');
        final className = paths.removeLast();
        final parent = paths.firstOrNull ?? '';
        final closestParent = paths.lastOrNull ?? '';

        String fullParent = paths.join('_');
        String propertyName =
            closestParent.isNotEmpty && closestParent != parent
                ? '$closestParent-$className'
                : className;

        final fullClassName = fullParent.isNotEmpty
            ? '$fullParent-$className'.asClassName
            : className.asClassName;

        final lowerCase = _toCamelCase(propertyName);
        final propertyString = fullParent.isNotEmpty
            ? 'final $fullClassName $lowerCase = const $fullClassName._();'
            : 'static const $fullClassName $lowerCase = $fullClassName._();';

        // If this is a subfolder, add the property to the parent folder class
        // otherwise we add it to the public top class
        //
        // This is done so the class structure follows the folder structure
        //
        // ie. assets/images/hyphie/default_background.png
        // will generate a class named _$ImagesHyphie with a String property called defaultBackground
        // and a class named _$Images with a static const _$ImagesHyphie hyphie
        // To access the asset path you would use AssetPaths.images.hyphie.defaultBackground
        // which reflects the folder structure
        //
        // Naming the bottom class _$ImagesHyphie instead of _$Hyphie is done to avoid conflicts
        if (parent.isNotEmpty) {
          final thisClassName = parent.asClassName;

          final statics = staticsMap[thisClassName] ?? [];
          if (!statics.contains(propertyString)) {
            statics.add(propertyString);
          }
          staticsMap[thisClassName] = statics;
        } else if (!baseClassStatics.contains(propertyString)) {
          baseClassStatics.add(propertyString);
        }

        final assetNoFilextension = assetName.split('.').first;
        final camelCase = _toCamelCase(assetNoFilextension);

        final property =
            'final String $camelCase = \'$assetFolder$assetName\';';

        final propertyList = propertiesMap[fullClassName] ?? [];
        propertyList.add(property);

        propertiesMap[fullClassName] = propertyList;
      }
    }

    for (var key in propertiesMap.keys) {
      final properties = propertiesMap[key];
      final statics = staticsMap[key];
      if (properties == null) {
        continue;
      }

      String code = 'final class $key {\n';
      code += '  const $key._();\n';
      for (final static in statics ?? []) {
        code += '  $static\n';
      }
      for (final property in properties) {
        code += '  $property\n';
      }
      code += '}\n';
      // check if it is the last key
      if (propertiesMap.keys.toList().indexOf(key) !=
          propertiesMap.keys.length - 1) {
        code += '\n';
      }
      dartCode += code;
    }

    String fullDartCode = '''
    // coverage:ignore-file
    // ignore_for_file: type=lint, unused_field

    // This file is generated by asset_code_generator
    // Do not modify this file manually
    // instead run `dart run asset_code_generator`

    abstract final class AssetPaths {
      ${baseClassStatics.join('\n  ')}
    }
    ''';

    fullDartCode += '\n$dartCode';

    // save dart code to asset_paths.dart
    final pathString = path ?? 'lib/asset_paths.g.dart';
    final assetPathsFile = File(pathString);
    assetPathsFile.writeAsStringSync(fullDartCode);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

extension _Convenience on String {
  String get asClassName {
    final upperCamelCase = _toUpperCamelCase(this);
    return '_\$$upperCamelCase';
  }
}
