import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'background_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../features/settings/controllers/app_settings.dart';

class BackgroundServiceIOS extends BackgroundService {
  bool statedTrip = false;
  Timer? timer;
  AudioPlayer? player;

  @override
  void exit() {
    stopTrip();
  }

  @override
  void init() {
    // Nothing to do here
  }

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