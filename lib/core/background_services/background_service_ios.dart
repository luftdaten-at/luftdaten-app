/*
   Copyright (C) 2023 Thomas Ogrisegg for luftdaten.at

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:luftdaten.at/core/config/app_settings.dart';
import 'package:luftdaten.at/core/background_services/background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class BackgroundServiceIOS extends BackgroundService {
  bool statedTrip = false;
  Timer? timer;
  AudioPlayer? player;

  @override
  void exit() {
    stopTrip();
  }

  @override
  void init() {}

  @override
  Future<bool> startTrip(int interval) async {
    startedTrip = true;
    if (AppSettings.I.wakelock) {
      WakelockPlus.enable();
    }
    mainHandler(null);
    timer = Timer.periodic(Duration(seconds: interval), (timer) {
      mainHandler(null);
    });
    player = AudioPlayer();
    await player?.setAsset('assets/audio/silent.wav');
    player?.setLoopMode(LoopMode.one);
    player?.play();
    return true;
  }

  @override
  void stopTrip() {
    startedTrip = false;
    timer?.cancel();
    WakelockPlus.disable();
    player?.stop();
    player = null;
  }
}
