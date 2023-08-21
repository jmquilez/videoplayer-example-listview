import 'dart:math';

//TODO: CHECK KEFRAME
import 'package:flutter/material.dart';
import 'package:video_player_example/screens/feed/video/reusable/reusable_video_list_controller_global.dart';
import 'package:video_player_example/utils/colors.dart';
import 'package:video_player_example/utils/video/model/video_list_data.dart';
import 'package:video_player_example/screens/feed/video/reusable/reusable_video_list_widget_clean_global.dart';
//import 'package:keframe/keframe.dart';
//import 'package:smooth/smooth.dart';

//TODO: stop video rendering when scrolling is too fast

//TODO: does this load the entire video?

//TODO: cache video?

//TODO: animate jank?

//NOTE: hls lags, live hls lags too, no matter size of video

class FeedVideoIntegrationGlobal extends StatefulWidget {
  final bool autoplay;
  final bool render;
  final bool controls;
  const FeedVideoIntegrationGlobal(
      {Key? key,
      required this.autoplay,
      required this.render,
      required this.controls})
      : super(key: key);

  @override
  State<FeedVideoIntegrationGlobal> createState() =>
      _FeedVideoIntegrationGlobalState();
}

class _FeedVideoIntegrationGlobalState
    extends State<FeedVideoIntegrationGlobal> {
  //TODO: create list with docs for cache extent
  final ScrollController _scrollController = ScrollController();
  double? mediaQHeight;
  double? currentCacheExtent;
  int documentLength = 0;
  final _random = Random();
  final List<String> _videos = [
    "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
    "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    ////'https://techslides.com/demos/sample-videos/small.mp4'
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WhatCarCanYouGetForAGrand.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/VolkswagenGTIReview.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4"
  ];
  List<VideoListData> dataList = [];
  ReusableVideoListControllerGlobal? videoListController;
  bool _canBuildVideo = true;
  int lastMilli = DateTime.now().millisecondsSinceEpoch;
  List<bool> isVideo = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _setupData();
    videoListController =
        ReusableVideoListControllerGlobal(widget.autoplay, widget.controls);
    _scrollController.addListener(() {
      print("CONTROLLER_PIXELS: ${_scrollController.position.pixels}");
      print("CURRENT_CACHE_EXTENT: $currentCacheExtent");
      print("DOCUMENT_LENGTH: $documentLength");
    });
  }

  void _setupData() {
    // index < itemCount
    for (int index = 0; index < 1000; index++) {
      //var randomVideoUrl = _videos[_random.nextInt(_videos.length)];
      var fixedVideoUrl = _videos[index % _videos.length];
      dataList.add(VideoListData("Video $index", fixedVideoUrl));
      isVideo.add(true /*false*/ /*_random.nextBool()*/);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _scrollController.dispose();
    videoListController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //NOTE: MEDIAQUERY JANKS
    /*final devicePixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    final physicalScreenSize = WidgetsBinding.instance.window.physicalSize;
    final mediaQueryHeight = physicalScreenSize.height;
    mediaQHeight = mediaQueryHeight;*/
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.airplay_rounded))
        ],
        backgroundColor: mobileBackgroundColor,
        centerTitle: true,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final now = DateTime.now();
          final timeDiff = now.millisecondsSinceEpoch - lastMilli;
          if (notification is ScrollUpdateNotification) {
            final pixelsPerMilli = notification.scrollDelta! / timeDiff;
            if (pixelsPerMilli.abs() > /*0.5*/ /*0.25*/ /*4*/ /*5*/
                1) {
              _canBuildVideo = false;
            } else {
              _canBuildVideo = true;
            }
            lastMilli = DateTime.now().millisecondsSinceEpoch;
          }

          if (notification is ScrollEndNotification) {
            _canBuildVideo = true;
            lastMilli = DateTime.now().millisecondsSinceEpoch;
          }

          return true;
        },
        child: ListView.builder(
            itemExtent: 550,
            physics: //CustomPhysics(),
                const BouncingScrollPhysics(), //need to be this physics, as with default ClampingScrollPhysics animation stops too early
            //and thus video doesn't get to be loaded while the scrolling animation is playing,
            //TODO, NOTE: does it improve performance?

            itemBuilder: (context, index) {
              // interleaved videos
              VideoListData videoListData = dataList[index];
              videoListData.index = index;
              print("CURRENT_LIST_INDEX: $index");
              return ReusableVideoListWidgetCleanGlobal(
                  videoListData: videoListData,
                  videoListController: videoListController,
                  canBuildVideo: _checkCanBuildVideo,
                  index: index,
                  render: widget.render);
            }),
      ),
    );
  }

  bool _checkCanBuildVideo() {
    return _canBuildVideo;
  }
}
