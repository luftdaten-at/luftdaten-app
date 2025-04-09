import 'package:convert/convert.dart';

class ChipId {
  final String? _chipId;
  final String? _mac;

  const ChipId.fromMac(String mac)
      : _mac = mac,
        _chipId = null;

  const ChipId.fromChipId(String chipId)
      : _chipId = chipId,
        _mac = null;

  const ChipId.unknown() : _chipId = '000000000000', _mac = null;

  String get chipId => _chipId ?? _mac!.chipId;

  String get mac => _mac ?? _chipId!.mac;

  // Serialization
  Map<dynamic, dynamic> toJson() {
    return {
      'chipId': chipId,
      'mac': mac,
    };
  }

  // Deserialization
  ChipId.fromJson(Map<dynamic, dynamic> json)
      : _chipId = json['chipId'],
        _mac = json['mac'],
        assert(json['chipId'] != null || json['mac'] != null, 'Either chipId or mac must be provided');
}

extension MacToChipId on String {
  String get chipId {
    List<int> macBytes = hex.decode(this);
    macBytes[macBytes.length - 1] = macBytes[macBytes.length - 1] - 1;
    List<int> chipIdBytes = macBytes.reversed.toList();
    return hex.encode(chipIdBytes);
  }

  String get mac {
    List<int> chipIdBytes = hex.decode(this);
    List<int> macBytes = chipIdBytes.reversed.toList();
    macBytes[macBytes.length - 1] = macBytes[macBytes.length - 1] + 1;
    return hex.encode(macBytes);
  }
}
