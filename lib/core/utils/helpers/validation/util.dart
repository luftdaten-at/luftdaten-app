import 'dart:typed_data';

class Util{
  static Uint8List toByteArray(dynamic input) {
    if (input is int) {
      // Convert int to 4-byte representation (32-bit)
      final byteData = ByteData(4);
      byteData.setInt32(0, input, Endian.big); // Change Endian if needed
      return byteData.buffer.asUint8List();
    } else if (input is double) {
      // Convert double to 8-byte representation (64-bit)
      final byteData = ByteData(8);
      byteData.setFloat64(0, input, Endian.big); // Change Endian if needed
      return byteData.buffer.asUint8List();
    } else if (input is String) {
      // Convert String to bytes using UTF-8 encoding
      return Uint8List.fromList(input.codeUnits);
    } else {
      throw ArgumentError('Input must be an int, double, or String.');
    }
  }
}