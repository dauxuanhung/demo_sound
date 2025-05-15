import 'package:demo_sound/recorder_data.dart';
import 'package:flutter/services.dart';

class NativeCaller {
  static const MethodChannel _channel = MethodChannel('com.sound.channel');

  // static Future<String> startRecorder() async {
  //   try {
  //     final String result = await _channel.invokeMethod('startRecorder');
  //     return result;
  //   } on PlatformException catch (e) {
  //     return "Failed to call native method: '${e.message}'.";
  //   }
  // }
  //
  // static Future<RecorderData?> stopRecorder() async {
  //   try {
  //     var path = await _channel.invokeMethod('stopRecorder');
  //     var bmp = await getBmp();
  //     var recorderData = RecorderData(path: path, bpm: bmp);
  //     return recorderData;
  //   } on PlatformException catch (_) {
  //     return null;
  //   }
  // }
  //
  // static Future<double?> getBmp() async {
  //   try {
  //     final result = await _channel.invokeMethod('getBmp');
  //     return result;
  //   } on PlatformException catch (e) {
  //     print("Failed to get result: '${e.message}'.");
  //     return null;
  //   }
  // }

  static Future<double?> getBpmOfFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod('getBmpOfFile', {"filePath": filePath});
      return double.tryParse(result.toString());
    } catch (e) {
      return null;
    }
  }
}
