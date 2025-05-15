// import 'dart:io';
// import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
// import 'package:path_provider/path_provider.dart';
//
// class BPMProcessor {
//   Future<String> adjustBPM(String inputFile, double tempoFactor) async {
//     final directory = await getApplicationDocumentsDirectory();
//     String outputFile = "${directory.path}/adjusted_audio.aac";
//
//     String command = '-i $inputFile -filter:a "atempo=$tempoFactor" $outputFile';
//
//     await FFmpegKit.execute(command);
//
//     return outputFile;
//   }
// }
