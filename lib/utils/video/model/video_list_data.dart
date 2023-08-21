class VideoListData {
  final String videoTitle;
  final String videoUrl;
  int? index;
  Duration? lastPosition;
  bool? wasPlaying = false;

  VideoListData(this.videoTitle, this.videoUrl, [this.index]);
}
