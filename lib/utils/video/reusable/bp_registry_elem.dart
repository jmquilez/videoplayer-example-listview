import 'package:video_player/video_player.dart';

class BpRegistryElem {
  VideoPlayerController? controller;
  DateTime? dt;
  int? index;
  BpRegistryElem(VideoPlayerController bp, DateTime dateTime, int? ind) {
    controller = bp;
    dt = dateTime;
    index = ind;
  }
}
