import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:h264/h264.dart';
import 'package:srtp_demo/changables.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';

class I2vSdk {
  String clVersion = "7.1.0";
  String wPlayerIp = "localhost";
  String wServerIp;
  int wServerPort = 8890;
  bool useSecureConnection = false;
  I2vPlayer? player;

  I2vSdk(String _wPlayerIp, this.wServerIp, int _wServerPort,
      bool useSecureConnection) {
    wPlayerIp = _wPlayerIp;
    wServerPort = _wServerPort;
    if (useSecureConnection) {
      this.useSecureConnection = useSecureConnection;
    }
  }

  I2vPlayer GetLivePlayer(String elId, String cameraId, String streamtype,
      String analyticType, String connectionmode) {
    player = I2vPlayer(
        elId,
        cameraId,
        "Live",
        streamtype,
        0,
        0,
        analyticType,
        connectionmode,
        clVersion,
        useSecureConnection,
        wPlayerIp,
        wServerIp,
        wServerPort);
    this.wPlayerIp = wPlayerIp;
    this.wServerIp = wServerIp;
    this.wServerPort = wServerPort;
    return player!;
  }

  I2vPlayer GetPlaybackPlayer(String elId, String cameraId, int startTime,
      int endTime, bool _playbackviaapache,
      [double playbackSpeed = 1.0]) {
    player = I2vPlayer(
        elId,
        cameraId,
        "PlayBack",
        "0",
        startTime,
        endTime,
        "",
        "tcp",
        clVersion,
        useSecureConnection,
        wPlayerIp,
        wServerIp,
        wServerPort,
        playbackSpeed);
    player?.wPlayerIp = wPlayerIp;
    player?.wServerIp = wServerIp;
    player?.wServerPort = wServerPort;
    return player!;
  }

  void SeekVideo(int startTime) {
    if (player != null && player?.mode != "Live") {
      // player?.SeekVideo(startTime);
    }
  }

  void Pause() {
    if (player != null && player?.mode != "Live") {
      // player?.Pause();
    }
  }

  void FastForward(double factor) {
    if (player != null && player?.mode != "Live") {
      // player?.FastForward(factor);
    }
  }
}

class I2vPlayer {
  String elId;
  String cameraId;
  String mode;
  String streamType;
  int startTime;
  int endTime;
  String analyticType;
  String connectionMode;
  String clVersion;
  bool useSecureConnection;
  double playbackSpeed = 1.0;
  bool IsEmptyUrl = false;
  bool doesStopRequested = false;
  bool isErrorMessageVisible = false;
  bool IsPlayerServerConnected = false;
  bool URL_Server_Not_Connected = false;
  bool isRgb = false;
  bool isVisible = true;
  bool isPlayerSet = false;
  dynamic w;
  dynamic jmuxer;
  int? width;
  int? height;
  String? svVersion;
  dynamic v;
  dynamic c;
  Function? errorCallback;
  Function? retryingCallback;
  String wPlayerIp = "localhost";
  String wServerIp;
  int wServerPort = 8890;

  I2vPlayer(
      this.elId,
      this.cameraId,
      this.mode,
      this.streamType,
      this.startTime,
      this.endTime,
      this.analyticType,
      this.connectionMode,
      this.clVersion,
      this.useSecureConnection,
      this.wPlayerIp,
      this.wServerIp,
      this.wServerPort,
      [this.playbackSpeed = 1.0]) {
    if (playbackSpeed < 0.5) playbackSpeed = 0.5;
    if (playbackSpeed > 5) playbackSpeed = 5;
    playbackSpeed = (playbackSpeed * 2).round() / 2;

    print("playbackSpeed Allowed: 0.5 to 5, with 0.5 step, 1 is default");
    print("playbackSpeed: $playbackSpeed");

    this.playbackSpeed = playbackSpeed;

    if (analyticType.isEmpty) analyticType = "";
    if (connectionMode.isEmpty) {
      connectionMode = "";
    } else {
      connectionMode = connectionMode.toLowerCase();
      if (connectionMode != "tcp" && connectionMode != "udp") {
        connectionMode = "";
      }
    }
  }

  void setErrorCallback(Function errorCallback) {
    this.errorCallback = errorCallback;
  }

  void setRetryingCallback(Function retryingCallback) {
    this.retryingCallback = retryingCallback;
  }

  void stop() {
    try {
      // removeErrorMessage();
      doesStopRequested = true;
      if (w != null) {
        w.sink.close();
      }
      v = null;
      c = null;
      if (isRgb) {
        // var c = document.getElementById("${elId}_canvas");
        // if (c != null) {
        //   var c_context = c.getContext('2d');
        //   c_context.clearRect(0, 0, width, height);
        //   c.parentNode.removeChild(c);
        // }
      } else {
        // var v = document.getElementById("${elId}_video");
        // if (v != null) {
        //   v.src = "";
        //   v.parentNode.removeChild(v);
        // }
      }
    } catch (ex) {
      print("wClient: Error in Stop Function");
    }
  }

  // void _sendMessageToWebView(String message) async {
  //   if (_controller != null) {
  //     var t = await _controller.runJavaScriptReturningResult(
  //         'typeof window.handleWebSocketMessage !== "undefined"');
  //     _controller.runJavaScript(
  //         'window.handleWebSocketMessage(${jsonEncode(message)});');
  //   }
  // }

  // void _injectJavaScriptHandler() {
  //   _controller.runJavaScript('''
  //     window.handleWebSocketMessage = function(message) {
  //       console.log('Received message from WebSocket:', message);
  //       // Handle the WebSocket message in your web content
  //     };
  //   ''');
  // }

  void play() async {
    var protocolType = "ws";
    var port = 8181;

    final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
    final FlutterFFmpegConfig _flutterFFmpegConfig = FlutterFFmpegConfig();

    // Uri uri = Uri.parse(
    //     "$protocolType://$wPlayerIp:$port?cameraId~~$cameraId&&mode~~$mode&&streamType~~$streamType&&startTime~~$startTime&&endTime~~$endTime&&analyticType~~$analyticType&&connectionMode~~$connectionMode&&wServerIp~~$wServerIp&&wServerPort~~$wServerPort&&clVersion~~$clVersion&&playbackSpeed~~$playbackSpeed");
    // Uri uri = Uri.parse(
    //     "ws://192.168.5.103:8181/?cameraId~~08dc9a7d-3ffe-ca14-00be-430210900000&&mode~~Live&&streamType~~0&&startTime~~0&&endTime~~0&&analyticType~~&&connectionMode~~&&wServerIp~~192.168.5.103&&wServerPort~~8890&&clVersion~~7.1.0&&playbackSpeed~~1");
    // print(uri.toString());

    // final _channel = WebSocketChannel.connect(uri);
    // _channel.stream.listen((message) {
    //   print(message);
    //   _sendMessageToWebView(message);
    // });

    // // ui.Image img =await   _loadImageFromBytes(rgba_data, 200, 200);
    // changables.videoContainerWidget.value = Container(
    //     width: 200,
    //     color: Colors.black,
    //     height: 200,
    //     child: WebViewWidget(
    //       controller: WebViewController()
    //         ..loadRequest(uri)
    //         ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //         ..addJavaScriptChannel(
    //           'handleWebSocketMessage',
    //           onMessageReceived: (JavaScriptMessage message) {
    //             print('Received message from JavaScript: ${message.message}');
    //           },
    //         )
    //         ..setNavigationDelegate(
    //           NavigationDelegate(
    //             onPageFinished: (String url) {
    //               _injectJavaScriptHandler();
    //             },
    //           ),
    //         ),
    //       // initialUrl: 'https://flutter.dev',
    //       // javascriptMode: JavascriptMode.unrestricted,
    //       // onWebViewCreated: (WebViewController webViewController) {
    //       //   _controller = webViewController;
    //       // },
    //     ));
    // _controller.loadRequest(Uri.parse(""));

    if (useSecureConnection) {
      protocolType = "wss";
      port = 8182;
    }
    removeErrorMessage();
    IsEmptyUrl = false;
    if (!IsEmptyUrl) showErrorMessage("Trying to Connect...");
    IsPlayerServerConnected = false;
    URL_Server_Not_Connected = false;

    Uri uri = Uri.parse(
        "$protocolType://$wPlayerIp:$port?cameraId~~$cameraId&&mode~~$mode&&streamType~~$streamType&&startTime~~$startTime&&endTime~~$endTime&&analyticType~~$analyticType&&connectionMode~~$connectionMode&&wServerIp~~$wServerIp&&wServerPort~~$wServerPort&&clVersion~~$clVersion&&playbackSpeed~~$playbackSpeed");
    print(uri.toString());
    w = WebSocketChannel.connect(uri);

    //player
    final directory = await getTemporaryDirectory();
    final String inputPath = '${directory.path}/input.h264';
    final String outputPath = '${directory.path}/output.mp4';
    bool isInitialised = false;

    VideoPlayerController _controller =
        VideoPlayerController.file(File(outputPath))
          ..initialize().then((_) {
            // setState(() {});
            isInitialised = true;
          });

    w.stream.listen((data) async {
      if (data == 'open') {
        doesStopRequested = false;
        w.sink.add('Hello Server!');
      }
      IsEmptyUrl = false;
      IsPlayerServerConnected = false;
      URL_Server_Not_Connected = false;
      var dataStr = data.toString();
      if (dataStr.startsWith("--version")) {
        svVersion = dataStr.substring(10);
        print("Client Version: $clVersion");
        print("Server Version: $svVersion");
        return;
      } else if (dataStr.startsWith("--servStatus")) {
        print(dataStr.substring(13));
        return;
      }
      switch (dataStr) {
        case "Server_ip_not_provided":
          var errMsg = "Please Provide Valid Server Ip";
          if (errorCallback != null) {
            errorCallback!(errMsg);
          }
          showErrorMessage(errMsg);
          return;
        case "Playback_Finished":
          var errMsg = "Playback_Finished";
          print(errMsg);
          if (errorCallback != null) {
            errorCallback!(errMsg);
          }
          stop();
          return;
        case "Video_Started":
          var errMsg = "Video_Started";
          print(errMsg);
          if (errorCallback != null) {
            errorCallback!(errMsg);
          }
          return;
        case "unable_to_play":
          var errMsg = "unable_to_play";
          print(errMsg);
          if (errorCallback != null) {
            errorCallback!(errMsg);
          }
          stop();
          return;
        case "EmptyUrl":
          IsEmptyUrl = true;
          var errMsg =
              mode == "Live" ? "Stream not Found" : "Recording not Found";
          if (errorCallback != null) {
            errorCallback!(errMsg);
          }
          showErrorMessage(errMsg);
          return;
        case "Player_Server_Not_Connected":
          IsPlayerServerConnected = true;
          var errMsg = "Player Server Not Connected ";
          if (errorCallback != null) {
            errorCallback!(errMsg);
          }
          showErrorMessage(errMsg);
          return;
        case "URL_Server_Not_Connected":
          URL_Server_Not_Connected = true;
          var errMsg = "URL Server Not Connected";
          if (errorCallback != null) {
            errorCallback!(errMsg);
          }
          showErrorMessage(errMsg);
          return;
      }
      print("rdbaData:: ${data}");
      if (data != 'mp4') {
        var rgba_data = Uint8List.fromList(data);

        File(inputPath).writeAsBytes(rgba_data);

        // Convert H264 to MP4 using FFmpeg
        _flutterFFmpeg.execute('-i $inputPath -c:v copy $outputPath');

        String outputFileContent = File(outputPath).readAsStringSync();
        print(outputFileContent);

        // Initialize video player with the output file

        if (isInitialised) {
          _controller.play();
        }
        // if (_controller != null && _controller.value.isInitialized) {
        changables.videoContainerWidget.value = VideoPlayer(_controller);
        // }

        // });
        // changables.videoContainerWidget.value  = Container(
        //     child: Image.memory(rgba_data, width: 200, height: 200),
        //     width: 200,
        //     color: Colors.black,
        //     height: 200,
        //   );

        if (isRgb) {
        } else {}
        isPlayerSet = true;
        // }
        if (isRgb) {
          var frameLen = 1000 / 24;
          var p = 0;

          var rgba_data = Uint8List.fromList(data);
          changables.videoContainerWidget.value = Container(
            child: Image.memory(rgba_data),
            width: 200,
            color: Colors.black,
            height: 200,
          );

          removeErrorMessage();
          isVisible = true;
        }
        // }
        if (data == 'error') {
          showErrorMessage("Player Not Connected...");
          w = null;
          if (jmuxer != null) {
            disposejmuxer();
          }
          c = null;
          v = null;
          isPlayerSet = false;
          isVisible = false;
          if (isRgb) {
            changables.videoContainerWidget.value = Container(
                child: Text("error Palying RGB",
                    style: TextStyle(color: Colors.red)),
                color: Colors.black,
                width: 200,
                height: 200);
          } else {
            changables.videoContainerWidget.value = Container(
                child:
                    Text("error Palying", style: TextStyle(color: Colors.red)),
                width: 200,
                height: 200,
                color: Colors.black);
          }
          Future.delayed(Duration(seconds: 3), () {
            if (!doesStopRequested) {
              play();
            }
          });
        }

        if (data == 'close') {
          if (doesStopRequested) {
            print('socket closed');
            removeErrorMessage();
          } else {
            print('socket closed and retrying...');
            if (IsPlayerServerConnected) {
              var errMsg = "Player Server Not Connected ";
              showErrorMessage(errMsg);
            } else if (URL_Server_Not_Connected) {
              var errMsg = "URL Server Not Connected";
              showErrorMessage(errMsg);
            } else if (IsEmptyUrl) {
              var errMsg =
                  mode == "Live" ? "Stream not Found" : "Recording not Found";
              showErrorMessage(errMsg);
            } else {
              showErrorMessage("Player Not Connected...");
            }
            w = null;
            if (jmuxer != null) {
              disposejmuxer();
            }
            c = null;
            v = null;
            isPlayerSet = false;
            isVisible = false;
            if (isRgb) {
              changables.videoContainerWidget.value = Container(
                  child: Text("remove video RGB",
                      style: TextStyle(color: Colors.red)),
                  width: 200,
                  height: 200,
                  color: Colors.black);
            } else {
              changables.videoContainerWidget.value = Container(
                  child: Text("error Palying",
                      style: TextStyle(color: Colors.red)),
                  width: 200,
                  height: 200,
                  color: Colors.black);
            }
            Future.delayed(Duration(seconds: 3), () {
              if (!doesStopRequested) {
                play();
              }
            });
          }
        }
      }
    });
  }

//  void _loadHtmlFromAssets() async {
//     String fileText = await rootBundle.loadString('assets/index.html');
//     _controller.loadUrl(Uri.dataFromString(
//       fileText,
//       mimeType: 'text/html',
//       encoding: Encoding.getByName('utf-8'),
//     ).toString());
//   }

  void disposejmuxer() {
    if (jmuxer != null) {
      jmuxer.destroy();
      jmuxer = null;
    }
  }

  Future<ui.Image> _loadImageFromBytes(
      Uint8List bytes, int width, int height) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
        bytes, width, height, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  void showErrorMessage(String msg) {
    // removeErrorMessage();
    isErrorMessageVisible = true;
    changables.videoContainerWidget.value = Container(
        child: Text(msg, style: TextStyle(color: Colors.red)),
        width: 200,
        height: 200,
        color: Colors.black);
    // var elIdDiv = document.getElementById(elId);
    // if (elIdDiv != null) {
    //   var div = document.createElement('div');
    //   div.id = "${elId}_error";
    //   div.innerHTML = msg;
    //   div.style.cssText = 'width: 100%;height: 100%;display: flex;justify-content: center;align-items: center;position: absolute;background: rgba(0,0,0,0.5);color: white;z-index: 1;';
    //   elIdDiv.appendChild(div);
    // }
  }

  void removeErrorMessage() {
    changables.videoContainerWidget.value = Container(
        child: Text("remove error", style: TextStyle(color: Colors.red)),
        width: 200,
        height: 200,
        color: Colors.black);
    // var errorDiv = document.getElementById("${elId}_error");
    // if (errorDiv != null) {
    //   errorDiv.parentNode.removeChild(errorDiv);
    // }
    // isErrorMessageVisible = false;
  }

  void SeekVideo(int startTime) {
    stop();
    this.startTime = startTime;
    play();
  }

  void Pause() {
    if (w != null) {
      w.sink.add("Pause");
    }
  }

  void FastForward(double factor) {
    if (w != null) {
      w.sink.add("FastForward:$factor");
    }
  }
}
