import 'package:asset_code_generator/asset_code_generator.dart'
    as asset_code_generator;

void main(List<String> arguments) {
  final directory = arguments.firstOrNull;
  asset_code_generator.generate(directory);
}
