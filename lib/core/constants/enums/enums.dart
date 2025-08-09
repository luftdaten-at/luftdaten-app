// Removed unused import: dart:collection
import 'package:flutter/material.dart' as material;


class Dimension {
  static const int pm0_1 = 1;
  static const int pm1_0 = 2;
  static const int pm2_5 = 3;
  static const int pm4_0 = 4;
  static const int pm10_0 = 5;
  static const int humidity = 6;
  static const int temperature = 7;
  static const int vocIndex = 8;
  static const int noxIndex = 9;
  static const int pressure = 10;
  static const int co2 = 11;
  static const int o3 = 12;
  static const int aqi = 13;
  static const int gasResistance = 14;
  static const int tvoc = 15;
  static const int no2 = 16;
  static const int sgp40RawGas = 17;
  static const int sgp40AdjustedGas = 18;
  static const int adjustedTempCube = 19;
  static const int uvs = 20;
  static const int light = 21;
  static const int altitude = 22;
  static const int uvi = 23;
  static const int lux = 24;
  static const int accelerationX = 25;
  static const int accelerationY = 26;
  static const int accelerationZ = 27;
  static const int gyroX = 28;
  static const int gyroY = 29;
  static const int gyroZ = 30;

  static final Map<int, List<dynamic>> thresholds = {
    temperature: [[18, 24], [Color.blue, Color.green, Color.red]],
    tvoc: [[220, 1430], [Color.green, Color.yellow, Color.red]],
    co2: [[800, 1000, 1400], [Color.green, Color.yellow, Color.orange, Color.red]],
    adjustedTempCube: [[18, 24], [Color.blue, Color.green, Color.red]],
    uvi: [[3, 6, 8, 11], [Color.green, Color.yellow, Color.orange, Color.red, Color.purple]],
    // PM1.0 thresholds with exact HSL colors
    pm1_0: [
      [9, 35, 55, 125, 250.5], 
      [Color.greenLight, Color.yellow, Color.orange, Color.red, Color.purple, Color.brownDark]
    ],
    // PM2.5 thresholds with exact HSL colors
    pm2_5: [
      [9, 35, 55, 125, 250.5], 
      [Color.greenLight, Color.yellow, Color.orange, Color.red, Color.purple, Color.brownDark]
    ],

    // PM10 thresholds with exact HSL colors
    pm10_0: [
      [54, 154, 254, 354, 424], 
      [Color.greenLight, Color.yellow, Color.orange, Color.red, Color.purple, Color.brownDark]
    ]
  };

  static final Map<int, String> _units = {
    pm0_1: "µg/m³",
    pm1_0: "µg/m³",
    pm2_5: "µg/m³",
    pm4_0: "µg/m³",
    pm10_0: "µg/m³",
    humidity: "%",
    temperature: "°C",
    vocIndex: "Index",
    noxIndex: "Index",
    pressure: "hPa",
    co2: "ppm",
    o3: "ppb",
    aqi: "Index",
    gasResistance: "Ω",
    tvoc: "ppb",
    no2: "ppb",
    sgp40RawGas: "Ω",
    sgp40AdjustedGas: "Ω",
    adjustedTempCube: "°C",
    accelerationX: "m/s²",
    accelerationY: "m/s²",
    accelerationZ: "m/s²",
    gyroX: "radians/s",
    gyroY: "radians/s",
    gyroZ: "radians/s",
    uvi: "UV Index",
    lux: "lx"
  };

  static final Map<int, String> _names = {
    pm0_1: "PM0.1",
    pm1_0: "PM1.0",
    pm2_5: "PM2.5",
    pm4_0: "PM4.0",
    pm10_0: "PM10.0",
    humidity: "Humidity",
    temperature: "Temperature",
    vocIndex: "VOC Index",
    noxIndex: "NOx Index",
    pressure: "Pressure",
    co2: "CO2",
    o3: "Ozone (O3)",
    aqi: "Air Quality Index (AQI)",
    gasResistance: "Gas Resistance",
    tvoc: "Total VOC",
    no2: "Nitrogen Dioxide (NO2)",
    sgp40RawGas: "SGP40 Raw Gas",
    sgp40AdjustedGas: "SGP40 Adjusted Gas",
    adjustedTempCube: "Adjusted Temperature Air Cube",
    uvs: "UVS",
    light: "Light",
    accelerationX: "Acceleration X",
    accelerationY: "Acceleration Y",
    accelerationZ: "Acceleration Z",
    gyroX: "Gyro X",
    gyroY: "Gyro Y",
    gyroZ: "Gyro Z",
    uvi: "UV Index",
    lux: "Lux"
  };

  static String getName(int dim){
    return _names[dim] ?? "Name not found";
  }

  static dynamic getColor(int dimensionId, double val) {
    if (!thresholds.containsKey(dimensionId)) return null;
    var th = [-double.infinity, ...thresholds[dimensionId]![0], double.infinity];
    var colors = thresholds[dimensionId]![1];
    for (int i = 0; i < th.length - 1; i++) {
      if (th[i] <= val && val < th[i + 1]) {
        var [r, g, b] = colors[i];
        return material.Color.fromRGBO(r, g, b, 1);
      }
    }
    return null;
  }
}

class Color {
  static const green = [0, 255, 0];
  static const greenLow = [0, 50, 0];
  static const blue = [0, 0, 255];
  static const cyan = [0, 255, 50];
  static const magenta = [255, 0, 20];
  static const white = [255, 150, 40];
  static const off = [0, 0, 0];
  static const greenLight = [128, 255, 128];  // HSL(120, 1, 0.75)
  static const yellow = [255, 255, 0];         // HSL(60, 1, 1)
  static const orange = [255, 170, 0];         // HSL(30, 1, 1)
  static const red = [255, 0, 0];              // HSL(0, 1, 1)
  static const purple = [179, 0, 179];         // HSL(300, 1, 0.7)
  static const brownDark = [128, 0, 32];      // HSL(330, 1, 0.5)
}
