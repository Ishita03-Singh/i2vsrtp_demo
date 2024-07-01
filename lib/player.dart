import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';
// import '../Models/open_camera.dart';
// import 'iplayer.dart';

class WebPlayer  {
  
  dynamic controller;
  
  dynamic mediaplayer;
 

  
  void dispose() {
    Localstore.instance.playerRef(50).dispose(controller);
  }

  
  void initialize(String playerId, String cameraId) {
    // controller = js.context.callMethod(
    //     'WebPlayerController', [serverIp, streamerIp, playerId, cameraId]);

    controller = Localstore.instance
        .playerRef(50)
        .initialize('192.168.0.48', '192.168.0.48', playerId, cameraId);
  }

  
  void play() {
    Localstore.instance.playerRef(50).play(controller);
  }

  // @override
  // void refresh(OpenCamera selectedCamera) {
  //   Localstore.instance.playerRef(50).dispose(controller);
  //   Future.delayed(const Duration(seconds: 1),
  //       () => Localstore.instance.playerRef(50).play(controller));
  // }

  
  void takesnapshot() {}
  
  void stop() {
    // print(controller);
    Localstore.instance.playerRef(50).dispose(controller);
  }

  
  Widget player(int index) {
    PlayerRef playerRef = Localstore.instance.playerRef(50);
    return playerRef.view(index);
  }

  
  void pause() {
    // js.context.callMethod('Pause', [controller]);
  }

  
  void resume() {
    // js.context.callMethod('Resume', [controller]);
  }

  
  void playPlayback(String playerId, String cameraId, String datetime) {
    controller = Localstore.instance.playerRef(50).initialize2(
        '192.168.0.104', '192.168.0.104', playerId, cameraId, datetime);
  }
  // @override
  // void setControllerStream(OpenCamera selectedCamera, int newStream) {
  //   String newStreamUrl = '';
  //   switch (newStream) {
  //     case 2:
  //       newStreamUrl = selectedCamera.camera.uRL2!;
  //       break;
  //     case 3:
  //       newStreamUrl = selectedCamera.camera.uRL3!;
  //       break;
  //     case 4:
  //       newStreamUrl = selectedCamera.camera.uRL4!;
  //       break;
  //     default:
  //       newStreamUrl = selectedCamera.camera.uRL1;
  //   }
  //   selectedCamera.currentStream = newStream;
  //   debugPrint(newStreamUrl);
  //   // (controller as WebPlayer)
  //   //     .setControllerStream(selectedCamera, selectedCamera.currentStream);
  //   // print((controller as VlcPlayerController).dataSource);
  // }
}