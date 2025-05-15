import 'package:demo_sound/track_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'main_state.freezed.dart';

@freezed
class MainState with _$MainState {
  const factory MainState({
    @Default(null) String? filePath,
    @Default(false) bool isPlaySound,
    @Default(false) bool isPlayTrack,
    @Default(false) bool isPlayMix,
    @Default(null) String? pathMix,
    @Default(null) int? bpm,
    @Default(null) String? outputPath,
    @Default(0) int mixState,
    @Default([]) List<TrackData> trackData,
    @Default(null) TrackData? trackSelected,
  }) = _MainState;
}
