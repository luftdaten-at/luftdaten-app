import 'dart:collection';

class Dimension {
  static const int PM0_1 = 1;
  static const int PM1_0 = 2;
  static const int PM2_5 = 3;
  static const int PM4_0 = 4;
  static const int PM10_0 = 5;
  static const int HUMIDITY = 6;
  static const int TEMPERATURE = 7;
  static const int VOC_INDEX = 8;
  static const int NOX_INDEX = 9;
  static const int PRESSURE = 10;
  static const int CO2 = 11;
  static const int O3 = 12;
  static const int AQI = 13;
  static const int GAS_RESISTANCE = 14;
  static const int TVOC = 15;
  static const int NO2 = 16;
  static const int SGP40_RAW_GAS = 17;
  static const int SGP40_ADJUSTED_GAS = 18;
  static const int ADJUSTED_TEMP_CUBE = 19;
  static const int UVS = 20;
  static const int LIGHT = 21;
  static const int ALTITUDE = 22;
  static const int UVI = 23;
  static const int LUX = 24;
  static const int ACCELERATION_X = 25;
  static const int ACCELERATION_Y = 26;
  static const int ACCELERATION_Z = 27;
  static const int GYRO_X = 28;
  static const int GYRO_Y = 29;
  static const int GYRO_Z = 30;

  static final Map<int, List<dynamic>> thresholds = {
    TEMPERATURE: [[18, 24], [Color.BLUE, Color.GREEN, Color.RED]],
    PM2_5: [[5, 15], [Color.GREEN, Color.YELLOW, Color.RED]],
    TVOC: [[220, 1430], [Color.GREEN, Color.YELLOW, Color.RED]],
    CO2: [[800, 1000, 1400], [Color.GREEN, Color.YELLOW, Color.ORANGE, Color.RED]],
    ADJUSTED_TEMP_CUBE: [[18, 24], [Color.BLUE, Color.GREEN, Color.RED]],
    UVI: [[3, 6, 8, 11], [Color.GREEN, Color.YELLOW, Color.ORANGE, Color.RED, Color.PURPLE]]
  };

  static final Map<int, String> _units = {
    PM0_1: "µg/m³",
    PM1_0: "µg/m³",
    PM2_5: "µg/m³",
    PM4_0: "µg/m³",
    PM10_0: "µg/m³",
    HUMIDITY: "%",
    TEMPERATURE: "°C",
    VOC_INDEX: "Index",
    NOX_INDEX: "Index",
    PRESSURE: "hPa",
    CO2: "ppm",
    O3: "ppb",
    AQI: "Index",
    GAS_RESISTANCE: "Ω",
    TVOC: "ppb",
    NO2: "ppb",
    SGP40_RAW_GAS: "Ω",
    SGP40_ADJUSTED_GAS: "Ω",
    ADJUSTED_TEMP_CUBE: "°C",
    ACCELERATION_X: "m/s²",
    ACCELERATION_Y: "m/s²",
    ACCELERATION_Z: "m/s²",
    GYRO_X: "radians/s",
    GYRO_Y: "radians/s",
    GYRO_Z: "radians/s",
    UVI: "UV Index",
    LUX: "lx"
  };

  static final Map<int, String> _names = {
    PM0_1: "PM0.1",
    PM1_0: "PM1.0",
    PM2_5: "PM2.5",
    PM4_0: "PM4.0",
    PM10_0: "PM10.0",
    HUMIDITY: "Humidity",
    TEMPERATURE: "Temperature",
    VOC_INDEX: "VOC Index",
    NOX_INDEX: "NOx Index",
    PRESSURE: "Pressure",
    CO2: "CO2",
    O3: "Ozone (O3)",
    AQI: "Air Quality Index (AQI)",
    GAS_RESISTANCE: "Gas Resistance",
    TVOC: "Total VOC",
    NO2: "Nitrogen Dioxide (NO2)",
    SGP40_RAW_GAS: "SGP40 Raw Gas",
    SGP40_ADJUSTED_GAS: "SGP40 Adjusted Gas",
    ADJUSTED_TEMP_CUBE: "Adjusted Temperature Air Cube",
    UVS: "UVS",
    LIGHT: "Light",
    ACCELERATION_X: "Acceleration X",
    ACCELERATION_Y: "Acceleration Y",
    ACCELERATION_Z: "Acceleration Z",
    GYRO_X: "Gyro X",
    GYRO_Y: "Gyro Y",
    GYRO_Z: "Gyro Z",
    UVI: "UV Index",
    LUX: "Lux"
  };

  static String get_name(int dim){
    return _names[dim] ?? "Name not found";
  }

  static dynamic getColor(int dimensionId, double val) {
    if (!thresholds.containsKey(dimensionId)) return null;
    var th = [-double.infinity, ...thresholds[dimensionId]![0], double.infinity];
    var colors = thresholds[dimensionId]![1];
    for (int i = 0; i < th.length - 1; i++) {
      if (th[i] <= val && val < th[i + 1]) {
        return colors[i];
      }
    }
    return null;
  }
}

class Color {
  static const RED = [255, 0, 0];
  static const GREEN = [0, 255, 0];
  static const GREEN_LOW = [0, 50, 0];
  static const BLUE = [0, 0, 255];
  static const YELLOW = [255, 100, 0];
  static const CYAN = [0, 255, 50];
  static const MAGENTA = [255, 0, 20];
  static const WHITE = [255, 150, 40];
  static const ORANGE = [255, 70, 0];
  static const PURPLE = [200, 0, 80];
  static const OFF = [0, 0, 0];
}
