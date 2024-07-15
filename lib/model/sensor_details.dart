import 'measured_data.dart';

class SensorDetails {
  LDSensor model;
  String? serialNumber, firmwareVersion, hardwareVersion, protocolVersion;

  SensorDetails(this.model, {
    this.serialNumber,
    this.firmwareVersion,
    this.hardwareVersion,
    this.protocolVersion,
  });

  List<MeasurableQuantity> get measuresQuantities => model.measures;

  // Serialization and de-serialization
  Map<String, dynamic> toJson() {
    return {
      'model': model.name,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
      if (hardwareVersion != null) 'hardwareVersion': hardwareVersion,
      if (protocolVersion != null) 'protocolVersion': protocolVersion,
    };
  }

  factory SensorDetails.fromJson(Map<String, dynamic> json) {
    return SensorDetails(
      LDSensor.fromName(json['model']),
      serialNumber: json['serialNumber'],
      firmwareVersion: json['firmwareVersion'],
      hardwareVersion: json['hardwareVersion'],
      protocolVersion: json['protocolVersion'],
    );
  }
}