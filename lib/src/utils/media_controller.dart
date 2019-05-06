import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart' as vidCont;
import 'package:vocab_utils/subtitle_controller.dart' as subCont;
import 'package:vocab_utils/subtitle_controller.dart';

class VideoProgressColors {
  VideoProgressColors({
    this.playedColor = const Color.fromRGBO(255, 0, 0, 0.7),
    this.bufferedColor = const Color.fromRGBO(50, 50, 200, 0.2),
    this.backgroundColor = const Color.fromRGBO(200, 200, 200, 0.5),
  });

  final Color playedColor;
  final Color bufferedColor;
  final Color backgroundColor;
}

class _VideoScrubber extends StatefulWidget {
  _VideoScrubber({
    @required this.child,
    @required this.videoController,
    @required this.subtitleController,
  });

  final Widget child;
  final vidCont.VideoPlayerController videoController;
  final subCont.SubtitleController subtitleController;

  @override
  _VideoScrubberState createState() => _VideoScrubberState();
}

class _VideoScrubberState extends State<_VideoScrubber> {
  bool _controllerWasPlaying = false;

  vidCont.VideoPlayerController get controller => widget.videoController;

  subCont.SubtitleController get subController => widget.subtitleController;

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final RenderBox box = context.findRenderObject();
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
      subController.seekTo(position);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: widget.child,
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          controller.play();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
    );
  }
}

class VideoProgressIndicator extends StatefulWidget {
  VideoProgressIndicator({
    this.videoController,
    this.subtitleController,
    VideoProgressColors colors,
    this.allowScrubbing,
    this.padding = const EdgeInsets.only(top: 5.0),
  }) : colors = colors ?? VideoProgressColors();

  final subCont.SubtitleController subtitleController;
  final vidCont.VideoPlayerController videoController;
  final VideoProgressColors colors;
  final bool allowScrubbing;
  final EdgeInsets padding;

  @override
  _VideoProgressIndicatorState createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<VideoProgressIndicator> {
  _VideoProgressIndicatorState() {
    vidListener = () {
      final vidCont.VideoPlayerValue vidValue = widget.videoController.value;
      if (!mounted) {
        return;
      }
      setState(() {});
      print('vidValue in medCont is: $vidValue');
    };

    subListener = () {
      final subCont.SubtitleValue subValue = widget.subtitleController.value;

      if (!mounted) {
        return;
      }
      if (subValue.reachedEnd) {
        // compensates the discrepancy between subtitle stream and video stream
        wait();
      }
      print('subVal in medCont is: $subValue');
    };
  }

  VoidCallback vidListener;

  VoidCallback subListener;

  vidCont.VideoPlayerController get videoController => widget.videoController;

  subCont.SubtitleController get subtitleController =>
      widget.subtitleController;

  VideoProgressColors get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    videoController.addListener(vidListener);
    subtitleController.addListener(subListener);
  }

  @override
  void deactivate() {
    videoController.removeListener(vidListener);
    subtitleController.removeListener(subListener);

    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    Widget progressIndicator;
    if (videoController.value.initialized) {
      final int duration = videoController.value.duration.inMilliseconds;
      final int position = videoController.value.position.inMilliseconds;

      int maxBuffering = 0;
      for (vidCont.DurationRange range in videoController.value.buffered) {
        final int end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      progressIndicator = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          LinearProgressIndicator(
            value: maxBuffering / duration,
            valueColor: AlwaysStoppedAnimation<Color>(colors.bufferedColor),
            backgroundColor: colors.backgroundColor,
          ),
          LinearProgressIndicator(
            value: position / duration,
            valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
            backgroundColor: Colors.transparent,
          ),
        ],
      );
    } else {
      progressIndicator = LinearProgressIndicator(
        value: null,
        valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
        backgroundColor: colors.backgroundColor,
      );
    }
    final Widget paddedProgressIndicator = Padding(
      padding: widget.padding,
      child: progressIndicator,
    );
    if (widget.allowScrubbing) {
      return _VideoScrubber(
        child: paddedProgressIndicator,
        videoController: videoController,
        subtitleController: subtitleController,
      );
    } else {
      return paddedProgressIndicator;
    }
  }
 // TODO(arman): remove this when voice analyzer is attached to utils/Analyzer
  void wait() async {
    print('is waiting to sync sub and vid');

    await Future.delayed(Duration(seconds: 4));
    videoController.pause();
  }
}

class TimerCounter extends StatefulWidget {
  TimerCounter(this.videoController);

  final videoController;

  @override
  _TimerCounterState createState() => _TimerCounterState();
}

class _TimerCounterState extends State<TimerCounter> {
  Duration time;

  _TimerCounterState() {
    _listener = () {
      if (!mounted) {
        return;
      }
      setState(() {
        getTime(videoController.position);
      });
    };
  }

  vidCont.VideoPlayerController get videoController => widget.videoController;

  VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    videoController.addListener(_listener);
  }

  @override
  void deactivate() {
    videoController.removeListener(_listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return time != null
        ? Text(
            _printDuration(time),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
            ),
          )
        : Text(
            '00:00:00',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
            ),
          );
  }

  getTime(Future<Duration> duration) async {
    Duration videoTime = await duration;

    setState(() {
      time = videoTime;
    });
  }
}

String _printDuration(Duration duration) {
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}
