import 'dart:math';

/// Generates Datahub device API keys aligned with firmware
/// [`Config.generate_random_api_key()`](https://github.com/luftdaten-at/firmware/blob/main/firmware/config.py).
abstract final class DatahubApiKeyGenerator {
  static const int defaultLength = 32;
  static const int minLength = 16;

  static const _charset = 'abcdefghijklmnopqrstuvwxyz0123456789';

  static String generate({int length = defaultLength, Random? random}) {
    if (length < minLength) {
      throw ArgumentError.value(length, 'length', 'must be at least $minLength');
    }
    final rng = random ?? Random.secure();
    return List.generate(length, (_) => _charset[rng.nextInt(_charset.length)]).join();
  }
}
