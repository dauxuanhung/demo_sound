import 'dart:async';
import 'dart:io';

import 'package:demo_sound/main_state.dart';
import 'package:demo_sound/track_data.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class MainViewModel extends StateNotifier<MainState> {
  final Ref _ref;

  MainViewModel(this._ref) : super(const MainState());

  void init() {
    var listData = [
      TrackData(name: 'Track 1', file: 'sound.mp3', bpm: 83),
      TrackData(name: 'Track 2', file: 'sound2.mp3', bpm: 91),
      TrackData(name: 'Track 3', file: 'sound3.mp3', bpm: 100),
      TrackData(name: 'Track 4', file: 'sound4.mp3', bpm: 110),
    ];
    if (mounted) state = state.copyWith(trackData: listData);
  }

  Future<String> copyAssetToCache(String assetPath, String filename) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File('${tempDir.path}/$filename');

    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<double?> getMeanVolume(String inputPath) async {
    String command = '-i "$inputPath" -af "volumedetect" -f null -';

    final session = await FFmpegKit.execute(command);
    final logs = await session.getLogs();

    for (var log in logs) {
      final msg = log.getMessage();
      if (msg.contains("mean_volume:")) {
        RegExp regex = RegExp(r'mean_volume: (-?\d+\.?\d*) dB');
        var match = regex.firstMatch(msg);
        if (match != null) {
          return double.parse(match.group(1)!);
        }
      }
    }
    return null;
  }

  Future<void> mixAudio(String assetAudio, String pickedAudio, String outputPath) async {
    if (state.mixState == 1) {
      return;
    }
    try {
      state = state.copyWith(mixState: 1);

      double originalBpm = state.bpm?.toDouble() ?? 120;
      double targetBpm = 83;
      double tempoFactor = targetBpm / originalBpm;

      String command = '-y -i "$assetAudio" -i "$pickedAudio" '
          '-filter_complex "[1:a]aloop=loop=-1:size=2e+09[a1]; '
          '[a1]atempo=$tempoFactor[a2]; [0:a]dynaudnorm[a0]; '
          '[a2]dynaudnorm[a3]; [a0][a3]amix=inputs=2:duration=shortest[a]" '
          '-map "[a]" -c:a libmp3lame -q:a 2 "$outputPath"';

      await FFmpegKit.executeAsync(command, (session) async {
        final returnCode = await session.getReturnCode();
        final logs = await session.getLogs();
        logs.forEach((log) => print("🎵 FFmpeg Log: ${log.getMessage()}"));

        if (ReturnCode.isSuccess(returnCode)) {
          print("✅ Mixing successful! File saved at $outputPath");
          state = state.copyWith(mixState: 2, outputPath: outputPath);
        } else {
          print("❌ Mixing failed with return code: $returnCode");
          state = state.copyWith(mixState: -1);
        }

        var outputFile = File(outputPath);
        var outputLength = await outputFile.length();
        if (outputLength == 0) {
          state = state.copyWith(mixState: -1);
        }
      });
    } catch (e) {
      print("❌ Lỗi khi mix audio: $e");
      state = state.copyWith(mixState: -1);
    }
  }

  void setFilePick(String path, double? bpm) {
    state = state.copyWith(filePath: path, bpm: bpm?.round(), mixState: 0);
  }

  Future<void> doMix() async {
    if (state.filePath != null && state.trackSelected != null) {
      String assetFilePath = await copyAssetToCache('assets/${state.trackSelected?.file}', '${state.trackSelected?.file}');
      Directory tempDir = await getTemporaryDirectory();
      String outputPath = '${tempDir.path}/mixed_audio.mp3';
      File file = File(outputPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      await mixAudio(assetFilePath, state.filePath!, outputPath);
      print("Mixed audio saved at: $outputPath");
    }
  }

  void setPlaySound(bool play) {
    state = state.copyWith(isPlaySound: play);
  }

  void setPlayTrack(bool play) {
    state = state.copyWith(isPlayTrack: play);
  }

  void setPlayMix(bool play) {
    state = state.copyWith(isPlayMix: play);
  }

  void selectTrack(TrackData trackData) {
    state = state.copyWith(trackSelected: trackData);
  }
}

final mainViewModel = StateNotifierProvider.autoDispose<MainViewModel, MainState>(
  (ref) {
    return MainViewModel(ref);
  },
);
