
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:text_unit/src/utils/media_controller.dart' as mediaCont;

import 'package:video_player/video_player.dart' as vidCont;
import 'package:vocab_utils/subtitle_controller.dart' as subCont;
import 'package:vocab_utils/utils/utils.dart';

void main() => runApp(MediaController());

class MediaController extends StatefulWidget {
  @override
  _MediaControllerState createState() => _MediaControllerState();
}

class _MediaControllerState extends State<MediaController> {
  vidCont.VideoPlayerController _videoController;
  subCont.SubtitleController _subtitleController;
  bool fullScreen = false;
  Utils utils = Utils();
  StreamSubscription<dynamic> _streamSubscription;
  String pathSrtDir = '/data/data/vo.tc.textunit/app_flutter/test/';
  List<dynamic> list = [];
  int volumeVal;
  int prevVol;
  bool mute;

  @override
  void initState() {
    _streamSubscription = utils.secondController.listen((dynamic data) {
      final Map<dynamic, dynamic> map = data;
      if (map.keys.first == 'completed') {
        setState(() {});
      }
    });
    final File file =
        File('/data/data/vo.tc.textunit/app_flutter/test/video.mp4');
    _videoController = vidCont.VideoPlayerController.file(file)..initialize();

    mute = false;
    volumeVal = (_videoController.value.volume * 100).toInt();
    init();
    super.initState();
  }

  Future<void> init() async {
    _subtitleController = subCont.SubtitleController.file(pathSrtDir);
    await _subtitleController.initialize();

    print('after initialization ${_subtitleController.value.pos}');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: <Widget>[
            Center(
              child: _videoController.value.initialized
                  ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: vidCont.VideoPlayer(_videoController))
                  : Container(),
            ),
            Transform(
              transform: Matrix4.translationValues(0, 0, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  subCont.SubtitleViewer(_subtitleController),
                  mediaCont.VideoProgressIndicator(
                    subtitleController: _subtitleController,
                    videoController: _videoController,
                    allowScrubbing: true,
                  ),
                  Container(
//                    height: 40.0,
                    color: Colors.black.withOpacity(0.7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        InkWell(
                          child: IconButton(
                              color: Colors.white.withOpacity(0.9),
                              icon: Icon(Icons.replay_10),
                              onPressed: () {
                                print(_videoController
                                    .value.position.inMilliseconds);
                                Duration moment = Duration(
                                    milliseconds: _videoController
                                            .value.position.inMilliseconds -
                                        10000);
                                setState(() {
                                  _videoController.seekTo(moment);
                                  _subtitleController.seekTo(moment);
                                });
                              }),
                        ),
                        InkWell(
                          child: IconButton(
                              color: Colors.white.withOpacity(0.9),
                              icon: Icon(Icons.forward_10),
                              onPressed: () {
                                print(_videoController
                                    .value.position.inMilliseconds);
                                Duration moment = Duration(
                                    milliseconds: _videoController
                                            .value.position.inMilliseconds +
                                        10000);
                                setState(() {
                                  _videoController.seekTo(moment);
                                  _subtitleController.seekTo(moment);
                                });
                              }),
                        ),
                        InkWell(
                          child: IconButton(
                            color: Colors.white.withOpacity(0.9),
                            icon: Icon(
//                      _videoController.value.isPlaying
//                          ? Icons.pause
//                          : Icons.play_arrow,
                              _subtitleController.value.isPlaying
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                            ),
                            onPressed: () {

                              if (!_videoController.value.isPlaying &&
                                  !_subtitleController.value.isPlaying) {
                                print(
                                    'subCont reachedEnd is; ${_subtitleController.value.reachedEnd}');

                                if (_subtitleController.value.reachedEnd) {
                                  print('case end in main');
                                  setState(() {});
                                } else {
                                  _videoController.play();
                                  _subtitleController.play();
                                  print('case true true');
                                  setState(() {});
                                }
                              } else {
                                _videoController.pause();
                                _subtitleController.pause();
                                print('case false false');
                                setState(() {});
                              }
                              print(
                                  'videoPlayer isPlaying: ${_videoController.value.isPlaying}');
                              print(
                                  'subtitlePlayer isPlaying: ${_subtitleController.value.isPlaying}');
                            },
                          ),
                        ),
                        InkWell(
                          child: IconButton(
                              color: Colors.white.withOpacity(0.9),
                              icon: fullScreen
                                  ? Icon(Icons.fullscreen_exit)
                                  : Icon(Icons.fullscreen),
                              onPressed: () {
                                setState(() {
                                  fullScreen
                                      ? SystemChrome.setEnabledSystemUIOverlays(
                                          SystemUiOverlay.values)
                                      : SystemChrome.setEnabledSystemUIOverlays(
                                          []);
                                  fullScreen = !fullScreen;
                                });
                              }),
                        ),
                        InkWell(
                          child: IconButton(
                            color: Colors.white.withOpacity(0.9),
                            icon:
                                Icon(mute ? Icons.volume_mute : Icons.volume_up),
                            onPressed: () {
                              if (mute) {
                                mute = !mute;
                                setState(() {
                                  volumeVal = prevVol;
                                  _videoController.setVolume(prevVol / 100);
                                });
                              } else {
                                mute = !mute;
                                prevVol =
                                    (_videoController.value.volume * 100).toInt();
                                setState(() {
                                  volumeVal = 0;
                                  _videoController.setVolume(0);
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            label: 'volume: $volumeVal',
                            activeColor: Colors.white.withOpacity(0.9),
                            inactiveColor: Colors.white.withOpacity(0.9),
                            value: volumeVal.toDouble(),
                            onChanged: (double value) {
                              print(value.round());

                              setState(() {
                                if (mute) {
                                  mute = !mute;
                                }
                                volumeVal = value.round();
                                _videoController.setVolume(value / 100);
                              });
                            },
                            min: 0,
                            max: 100,
                          ),
                        ),
                        mediaCont.TimerCounter(_videoController)
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _subtitleController.dispose();
    _videoController.dispose();

    _streamSubscription.cancel();
  }
}
