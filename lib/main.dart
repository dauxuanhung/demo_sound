import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'audio_player.dart';
import 'main_view_model.dart';
import 'native_caller.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: FToastBuilder(),
      debugShowCheckedModeBanner: false,
      home: AudioScreen(),
    );
  }
}

class AudioScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _AudioScreenState();
  }
}

class _AudioScreenState extends ConsumerState<AudioScreen> {
  final AudioPlayerService _playerService = AudioPlayerService();
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        ref.read(mainViewModel.notifier).init();
      },
    );
    fToast = FToast();
    fToast.init(context);
    _playerService.player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        ref.read(mainViewModel.notifier).setPlaySound(false);
      }
    });
    _playerService.playerMix.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        ref.read(mainViewModel.notifier).setPlayMix(false);
      }
    });
    _playerService.playerSound.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        ref.read(mainViewModel.notifier).setPlayTrack(false);
      }
    });
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  void _stopMusic() {
    ref.read(mainViewModel.notifier).setPlayMix(false);
    ref.read(mainViewModel.notifier).setPlayTrack(false);
    ref.read(mainViewModel.notifier).setPlaySound(false);
    _playerService.stopMusic();
    _playerService.stopMix();
    _playerService.stopSoundMix();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Music mix")),
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: InkWell(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(8)), border: Border.all(color: Colors.deepPurpleAccent, width: 1)),
                    child: Column(
                      children: [
                        Icon(
                          Icons.file_upload,
                          color: Colors.deepPurpleAccent,
                        ),
                        Text(
                          "Upload beat",
                        )
                      ],
                    ),
                  ),
                  onTap: () {
                    _stopMusic();
                    pickFile();
                  },
                )),
                const SizedBox(height: 12),
                Center(
                  child: Consumer(
                    builder: (context, ref, child) {
                      var isPlay = ref.watch(mainViewModel.select((value) => value.isPlaySound));
                      var filePath = ref.watch(mainViewModel.select((value) => value.filePath));
                      var bpm = ref.watch(mainViewModel.select((value) => value.bpm));
                      return filePath != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _stopMusic();
                                    if (isPlay) {
                                      ref.read(mainViewModel.notifier).setPlaySound(false);
                                    } else {
                                      _playerService.playMusic(ref.read(mainViewModel.select((value) => value.filePath)));
                                      ref.read(mainViewModel.notifier).setPlaySound(true);
                                    }
                                  },
                                  child: Icon(
                                    isPlay ? Icons.pause : Icons.play_arrow,
                                    color: Colors.deepPurpleAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(child: Text("${filePath.substring(filePath.lastIndexOf("/") + 1)} - BPM ${bpm.toString()}"))
                              ],
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Consumer(
                    builder: (context, ref, child) {
                      var isPlay = ref.watch(mainViewModel.select((value) => value.isPlayTrack));
                      var trackSelected = ref.watch(mainViewModel.select((value) => value.trackSelected));
                      return trackSelected != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _stopMusic();
                                    if (isPlay) {
                                      ref.read(mainViewModel.notifier).setPlayTrack(false);
                                    } else {
                                      _playerService.playSoundMix(trackSelected.file);
                                      ref.read(mainViewModel.notifier).setPlayTrack(true);
                                    }
                                  },
                                  child: Icon(
                                    isPlay ? Icons.pause : Icons.play_arrow,
                                    color: Colors.deepPurpleAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(child: Text('${trackSelected.name} - BPM ${trackSelected.bpm?.round()}'))
                              ],
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, child) {
                    var listData = ref.watch(mainViewModel.select((value) => value.trackData));
                    return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        height: 140,
                        child: ListView.separated(
                          itemCount: listData.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Consumer(
                              builder: (context, ref, child) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                                      border: Border.all(color: Colors.deepPurpleAccent, width: 1)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.music_note, color: Colors.deepPurpleAccent),
                                      const SizedBox(width: 12),
                                      Text('${listData[index].name} - BPM ${listData[index].bpm?.round()}'),
                                      ElevatedButton(
                                        onPressed: () {
                                          _stopMusic();
                                          ref.read(mainViewModel.notifier).selectTrack(listData[index]);
                                        },
                                        child: const Text('Select'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) {
                            return const SizedBox(width: 12);
                          },
                        ));
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: Consumer(
                    builder: (context, ref, child) {
                      var mixState = ref.watch(mainViewModel.select((value) => value.mixState));
                      var filePath = ref.watch(mainViewModel.select((value) => value.filePath));
                      var trackSelected = ref.watch(mainViewModel.select((value) => value.trackSelected));
                      return filePath != null && trackSelected != null
                          ? Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        _stopMusic();
                                        ref.read(mainViewModel.notifier).doMix();
                                      },
                                      child: const Text("Mix Audio"),
                                    ),
                                    const SizedBox(width: 12),
                                    if (mixState != 0)
                                      Text(mixState == 1
                                          ? 'Processing...'
                                          : mixState == 2
                                              ? 'Success'
                                              : 'Error')
                                  ],
                                ),
                                if (mixState == 2)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          var hasPermission = await requestWriteExternalStoragePermission(context);
                                          if (hasPermission) {
                                            var outputPath = ref.watch(mainViewModel.select((value) => value.outputPath));
                                            Directory downloadsDir = Directory("");
                                            if (Platform.isAndroid) {
                                              downloadsDir = Directory("/storage/emulated/0/Download");
                                            } else {
                                              downloadsDir = await getApplicationDocumentsDirectory();
                                            }
                                            String targetPath =
                                                '${downloadsDir.path}/${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}mixed_audio.mp3';
                                            await File(outputPath!).copy(targetPath);
                                            print("targetPath${targetPath}");
                                            fToast.showToast(child: const Text("Download success"));
                                          }
                                        },
                                        child: const Text("Download"),
                                      ),
                                      const SizedBox(width: 12),
                                      Consumer(
                                        builder: (context, ref, child) {
                                          var isPlayMix = ref.watch(mainViewModel.select((value) => value.isPlayMix));

                                          return ElevatedButton(
                                            onPressed: () {
                                              _stopMusic();
                                              if (isPlayMix) {
                                                ref.read(mainViewModel.notifier).setPlayMix(false);
                                              } else {
                                                ref.read(mainViewModel.notifier).setPlayMix(true);
                                                _playerService.playMix(ref.read(mainViewModel.select((value) => value.outputPath)));
                                              }
                                            },
                                            child: Text("${isPlayMix ? "Stop" : "Play"} audio mixed"),
                                          );
                                        },
                                      )
                                    ],
                                  )
                              ],
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            _buildLoadingView()
          ],
        ));
  }

  Widget _buildLoadingView() {
    return Consumer(
      builder: (_, ref, child) {
        var mixState = ref.watch(mainViewModel.select((value) => value.mixState));
        if (mixState == 1) {
          return Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4)),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<bool> requestWriteExternalStoragePermission(BuildContext context) async {
    PermissionStatus status = await Permission.storage.request();
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 29 ? true : status == PermissionStatus.granted;
    }
    return status == PermissionStatus.granted;
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['mp3', 'wav', 'aac']);
    if (result != null) {
      File file = File(result.files.single.path!);
      double? bpm = await NativeCaller.getBpmOfFile(file.path);
      if (bpm != 0) {
        ref.read(mainViewModel.notifier).setFilePick(file.path, bpm);
      } else {
        fToast.showToast(child: const Text("Cannot open file. Please select other file"));
      }
    }
  }
}
