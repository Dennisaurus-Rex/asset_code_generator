import 'package:asset_code_generator/asset_code_generator.dart'
    as asset_code_generator;

void main(List<String> arguments) {
  final path = arguments.isNotEmpty ? arguments.first : null;
  asset_code_generator.generate(path);
}
