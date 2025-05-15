import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorder {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? recordedFilePath;
  final recorder = FlutterSoundRecorder();
  Future<void> initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    recordedFilePath = "${directory.path}/recorded_audio.aac";
    await _recorder.startRecorder(
      toFile: recordedFilePath,
      codec: Codec.aacADTS, // Định dạng AAC
    );
    isRecording = true;
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    isRecording = false;
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}
