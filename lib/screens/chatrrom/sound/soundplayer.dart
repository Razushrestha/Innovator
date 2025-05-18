import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playSound() async {
    await _player.play(AssetSource('icon/multi-pop-5-188168.mp3'));
  }

  Future<void> stopSound() async {
    await _player.stop();
  }
}

