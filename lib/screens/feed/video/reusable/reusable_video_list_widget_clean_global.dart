import 'dart:async';

import 'package:video_player/video_player.dart';
import 'package:video_player_example/screens/feed/video/reusable/reusable_video_list_controller_global.dart';
import 'package:video_player_example/utils/video/model/video_list_data.dart';
import 'package:video_player_example/utils/video/reusable/bp_registry_elem.dart';
import 'package:flutter/material.dart';
//import 'package:keframe/keframe.dart';
import 'package:visibility_detector/visibility_detector.dart';

//KEY NOTE: TOO MANY EVENT LISTENERS CAUSE JANK (TEST WITHOUT REMOVING THEM)
class ReusableVideoListWidgetCleanGlobal extends StatefulWidget {
  final VideoListData? videoListData;
  ReusableVideoListControllerGlobal? videoListController;
  final Function? canBuildVideo;
  final int? index;
  final ScrollController? controller;
  bool? render;
  ReusableVideoListWidgetCleanGlobal(
      {Key? key,
      this.videoListData,
      this.videoListController,
      this.canBuildVideo,
      this.index,
      this.controller,
      required this.render})
      : super(key: key);

  @override
  _ReusableVideoListWidgetCleanGlobalState createState() =>
      _ReusableVideoListWidgetCleanGlobalState();
}

class _ReusableVideoListWidgetCleanGlobalState
    extends State<ReusableVideoListWidgetCleanGlobal> {
  VideoListData? get videoListData => widget.videoListData;
  VideoPlayerController? controller;
  //TODO: CHECK WHEN IF NO CONTROLLERS LEFT
  StreamController<VideoPlayerController?>
      betterPlayerControllerStreamController = StreamController.broadcast();
  bool _initialized = false;
  Timer? _timer;
  VideoPlayerOptions _config = VideoPlayerOptions(mixWithOthers: true);
  late VoidCallback onPlayerEvent;
  bool _videoRender = true;

  //TODO: CHANGE VISIBLEFRACTION AND SCROLLING SPEED TRIGGERING FOR CANBUILDVIDEO? TOO?
  @override
  void initState() {
    super.initState();
    onPlayerEvent = () {
      //setState(() {});
      print("500ms tick received");
      print("video position: ${controller?.value.position}");
    };
  }

  // REMOVE FROM CACHE??
  @override
  void dispose() {
    betterPlayerControllerStreamController.close();
    super.dispose();
  }

  // Computationally expensive
  int _factorial(int n) {
    return (n == 0) ? 1 : n * _factorial(n - 1) * _factorial(n - 2);
  }

  void expensive(int n) {
    String str = "";
    for (var i = 0; i < n; i++) {
      str = '$str $i';
    }
    print(str);
  }

  //FLUTTER VERSION IN BETA, ERROR THERE??
  Future<void> _setupController() async {
    print("setting controller up");
    if (controller == null) {
      //NOTE: returned by value??
      controller = await widget.videoListController!
          .getBetterPlayerControllerReassign(widget.index!);

      //TODO, NOTE: ADDING HERE MAKES "Hola" SCREEN APPEAR FREQUENTLY
      /*if (!betterPlayerControllerStreamController.isClosed &&
          controller != null) {
        betterPlayerControllerStreamController.add(controller);
      }*/
      if (controller != null) {
        final oldController = controller;

        // Registering a callback for the end of next frame
        // to dispose of an old controller
        // (which won't be used anymore after calling setState)
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await oldController!.dispose();

          // Initing new controller
          // TODO, CHECK: how many ms have to be buffered in order for the video to play
          controller = VideoPlayerController.networkUrl(
              Uri.parse(videoListData!.videoUrl),
              videoPlayerOptions: _config)
            ..initialize().then((_) {
              controller!.setLooping(true);
              //NOTE: janking??
              //TODO: check if necessary
              setState(() {
                _videoRender = false;
              });
              print("controller initialized");
              //NOTE: null check operator used on a null value below
              //NOTE: not playing already renders the first frame (thanks to setState)
              controller!.play();
              //setState(() {});
              //do what you want.
            });
        });

        //TODO: TRY ABUSING SHARED CONNECTION
        if (!betterPlayerControllerStreamController.isClosed) {
          betterPlayerControllerStreamController.add(controller);
        }
        //TODO, NOTE: REPLACE "?" WITH "!"? --> null check operator used on a null value, revise bug
        //controller!.addListener(onPlayerEvent);
      }
    }
  }

  //TODO, CHECK: IS GETTING CALLED EVERY TIME?
  Future<void> _freeController() async {
    //??
    //TODO: CHECK FOR JITTER, WHETHTER IT IS DEFINITIVE OR NOT
    if (!_initialized) {
      _initialized = true;
      //return;
    }
    if (controller != null) {
      await controller!.pause();
      //EVENT LISTENER RELATED JANK??
      controller!.removeListener(onPlayerEvent);
      BpRegistryElem? elem =
          widget.videoListController!.getElem(widget.index! /*controller!*/);
      widget.videoListController!.freeBetterPlayerController(elem);
      //TODO, NOTE: it is causing line 103 to throw null check operator error
      controller = null;
      //TODO: await a future that sets up controller, then set it to null?
      if (!betterPlayerControllerStreamController.isClosed) {
        betterPlayerControllerStreamController.add(null);
      }
    }
  }

  ///TODO: Handle "setState() or markNeedsBuild() called during build." error
  ///when fast scrolling through the list
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              videoListData!.videoTitle,
              style: const TextStyle(fontSize: 50),
            ),
          ),
          VisibilityDetector(
            key: Key(hashCode.toString() + DateTime.now().toString()),
            onVisibilityChanged: (info) async {
              if (!widget.canBuildVideo!()) {
                //AWAIT??
                //TODO: CHECK KEYS??
                _timer?.cancel();
                //NOTE: NO CHILD WIDGETS TEND TO JANK MORE
                //TODO, NOTE: NEEDED?
                _timer = null;
                //WIFI CONNECTION IMPACT??
                //Simulatneous creation of several timers blocks ui when loading multiple videos at a time?
                //TODO: play with delays
                _timer = Timer(
                    const Duration(milliseconds: 250 /*100*/ /*250*/ /*500*/),
                    () async {
                  //TODO, NOTE: Synchronized, as in java?
                  if (info.visibleFraction >= 0.9 /*0.9*/ /*0.8*/ /*0.6*/) {
                    if (controller == null) {
                      print("RESETUP-A");
                      await _setupController();
                    }
                  } else /*if (info.visibleFraction <= 0.3)*/ {
                    print("FREE-A");
                    if (!_videoRender) {
                      _videoRender = true;
                      return;
                    }
                    await _freeController();
                  }
                });
                return;
              }
              //check if "_setupController" calls do not match
              if (info.visibleFraction >= 0.9 /*0.9*/ /*0.8*/ /*0.6*/) {
                if (controller == null) {
                  print("RESETUP-B");
                  await _setupController();
                }
                //NOTE: controllers not being freed? buffering??
              } else /*if (info.visibleFraction <= 0.3)*/ {
                print("FREE-B");
                //TODO: notify glitch
                if (!_videoRender) {
                  _videoRender = true;
                  return;
                }
                await _freeController();
              }
            },
            //CONDITIONAL JANKING??
            // TODO: REMOVE ALL WIDGETS, LEAVE VIDEO ONLY AND SEE WHAT HAPPENS
            // TODO SEARCH, NOTE: THE MORE WIDGETS INSIDE STREAMBUILDER, THE LAGGIER?
            child: StreamBuilder<VideoPlayerController?>(
              stream: betterPlayerControllerStreamController.stream,
              builder: (context, snapshot) {
                print(
                    "CURR_INDEX: ${widget.index}, controller: $controller"); // wait for controller to be added to stream and then re-render
                // NOTE: widget tree optimized to render least children possible
                if (widget.render!) {
                  return /*Column(
                  children: [*/
                      //ADDING OVERHEAD??
                      AspectRatio(
                    aspectRatio: 16 / 9,
                    child: controller != null
                        ? VideoPlayer(
                            controller!,
                          )
                        : Container(
                            color: Colors.black,
                            child: const Center(child: Text("Loading"))
                            //TODO: REMOVE CENTER?
                            //TODO: CALCULATE HOW MUCH OVERHEAD EACH WIDGET ADDS --> MIGHT BE INTERESTING

                            ),
                  );
                } else {
                  return /*Column(
                  children: [*/
                      //ADDING OVERHEAD??
                      AspectRatio(
                    aspectRatio: 16 / 9,
                    child: controller != null
                        ? const Text("Loaded")
                        : Container(
                            color: Colors.black,
                            child: const Center(child: Text("Loading"))
                            //TODO: REMOVE CENTER?
                            //TODO: CALCULATE HOW MUCH OVERHEAD EACH WIDGET ADDS --> MIGHT BE INTERESTING

                            ),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(widget.videoListData!.videoUrl),
          ),
          Center(
            child: Wrap(children: [
              ElevatedButton(
                child: const Text("Play"),
                onPressed: () {
                  controller!.play();
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                child: const Text("Pause"),
                onPressed: () {
                  controller!.pause();
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                child: const Text("Set max volume"),
                onPressed: () {
                  controller!.setVolume(1.0);
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  //TODO, NOTE: RELATED TO GLOBALKEYS, CHECK
  @override
  void deactivate() {
    if (controller != null) {
      videoListData!.wasPlaying = controller!.value.isPlaying;
    }
    _initialized = true;
    super.deactivate();
  }
}
