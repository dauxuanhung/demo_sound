import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer player = AudioPlayer();
  final AudioPlayer playerMix = AudioPlayer();
  final AudioPlayer playerSound = AudioPlayer();

  Future<void> playMusic(String? url) async {
    if (url != null) {
      await player.setFilePath(url);
      player.play();
    }
  }

  Future<void> playSoundMix(String? file) async {
    print("file${file}");
    try {
      await playerSound.setAsset('assets/$file');
      await playerSound.play();
    } catch (_) {}
  }

  Future<void> playMix(String? url) async {
    if (url != null) {
      await playerMix.setFilePath(url);
      playerMix.play();
    }
  }

  Future<void> stopMix() async {
    try {
      await playerMix.stop();
    } catch (_) {}
  }

  Future<void> stopSoundMix() async {
    try {
      await playerSound.stop();
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    try {
      await player.stop();
    } catch (_) {}
  }

  void dispose() {
    playerMix.dispose();
    playerSound.dispose();
    player.dispose();
  }
}
