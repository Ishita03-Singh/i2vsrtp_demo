import 'dart:html';
import 'dart:typed_data';
// import 'dart:web_audio';
// import 'dart:web_gl';
// import 'dart:web_socket';

class WebLiveController {
  String playerIP;
  String serverIp;
  String playerId;
  String cameraId;
  var playerObj;

  WebLiveController(this.playerIP, this.serverIp, this.playerId, this.cameraId) {
    var sdk = I2vSdk(playerIP, serverIp, false, 8890);
    playerObj = sdk.getLivePlayer(playerId, cameraId, "0", "0", "");

    playerObj.setErrorCallback((err) {
      print(err);
    });

    playerObj.setRetryingCallback((err) {
      print("disconnected, retrying to connect!!");
    });

    playerObj.stop(() {
      print("stop called!!!");
    });

    // playerObj.play();
    // print("In Live_Play");
    // print(playerObj);
  }
}

class I2vSdk {
  String playerIp = "localhost";
  bool useSecureConnection = false;

  I2vSdk(this.playerIp, String serverIp, bool useSecureConnection, int port);

  void initPlayer(
      String serverIP,
      String serverType,
      Function successCallback,
      Function errorCallback,
      String _playerIp,
      bool useSecureConnection) {
    if (_playerIp.isNotEmpty) {
      this.playerIp = _playerIp;
    }
    if (useSecureConnection) {
      this.useSecureConnection = useSecureConnection;
    }
    var protocolType = "ws";
    var port = 8181;
    if (this.useSecureConnection) {
      protocolType = "wss";
      port = 8182;
    }
    var wc = WebSocket('$protocolType://$playerIp:$port?serverIp$serverIP');
    wc.onMessage.listen((e) {
      if (e.data == "Ok" || e.data == "Init") {
        successCallback();
      } else {
        errorCallback(e.data);
        print(e.data);
      }
      wc.close();
    });

    wc.onError.listen((e) {
      var errMsg = "Not able to connect to player.";
      print(errMsg);
      errorCallback(errMsg);
      wc.close();
    });
  }

  I2vPlayer getLivePlayer(String elId, String cameraId, String mode,
      String streamtype, String useTranscoding) {
    var player = I2vPlayer(elId, cameraId, mode, streamtype, useTranscoding, 0,
        "", this.useSecureConnection);
    player.playerIp = this.playerIp;
    return player;
  }
}

class I2vPlayer {
  String elId;
  String cameraId;
  String mode;
  String streamtype;
  String useTranscoding;
  bool useSecureConnection = false;
  bool doesStopRequested = false;
  String? playerIp;
  dynamic v, i, b, m, intS, lastSegment;
  bool isPlayerSet = false;
  bool isJpeg = false;
  bool isSourceReady = false;
  Function? errorCallback;
  Function? retryingCallback;

  I2vPlayer(
      this.elId,
      this.cameraId,
      this.mode,
      this.streamtype,
      this.useTranscoding,
      int ctrlInputRate,
      String startTime,
      this.useSecureConnection);

  void setErrorCallback(Function callback) {
    this.errorCallback = callback;
  }

  void setRetryingCallback(Function callback) {
    this.retryingCallback = callback;
  }

  void stop(Function callback) {
    this.doesStopRequested = true;
    this.v?.close();
    this.v = null;
    this.m = null;
    if (this.isJpeg) {
      var i = document.getElementById('${this.elId}_img');
      i?.remove();
    } else {
      var v = document.getElementById('${this.elId}_video');
      v?.remove();
    }
  }

  void initializeMediaSource() {
    this.m = MediaSource();
    var mime = 'video/mp4; codecs="avc1.4D0020"';
    if (!MediaSource.isTypeSupported(mime)) {
      return;
    }
    this.m.on['sourceopen'] = (e) {
      try {
        this.v.play();
      } catch (ex) {
        e = ex;
      }
      this.b = this.m.addSourceBuffer(mime);
      this.b.mode = 'sequence';
      this.b.on['updateend'] = (e) {
        if (this.b.updating) {
          return;
        }
        if (this.lastSegment != null) {
          this.b.appendBuffer(this.lastSegment);
          this.lastSegment = null;
        }
        if (this.b.buffered.length == 0) {
          return;
        }
        var currentTime = this.v.currentTime;
        var start = this.b.buffered.start(0);
        var end = this.b.buffered.end(0);
        var past = currentTime - start;
        if (past > 20 && currentTime < end && !this.b.updating) {
          this.b.remove(start, currentTime - 4);
        }
      };
      if (!this.b.updating && this.m.readyState == 'open' && this.intS != null) {
        this.b.appendBuffer(this.intS);
      }
      this.isSourceReady = true;
    };
  }

  String arrayBufferToBase64(Uint8List buffer) {
    var binary = '';
    for (var i = 0; i < buffer.length; i++) {
      binary += String.fromCharCode(buffer[i]);
    }
    return window.btoa(binary);
  }

  void play() {
    var protocolType = "ws";
    var port = 8181;
    if (this.useSecureConnection) {
      protocolType = "wss";
      port = 8182;
    }
    this.initializeMediaSource();
    this.v = WebSocket(
        '$protocolType://${this.playerIp}:$port?cameraId${this.cameraId}&&id${this.elId}&&useTranscoding${this.useTranscoding}&&startTime&&mode${this.mode}&&streamtype${this.streamtype}&&ctrlInputRate');
    this.v.binaryType = 'arraybuffer';
    this.v.onOpen.listen((event) {
      this.doesStopRequested = false;
      this.v.send('Hello Server!');
    });
    this.v.onClose.listen((event) {
      if (this.doesStopRequested) {
        print('socket closed');
      } else {
        print('socket closed and retrying...');
        if (this.isPlayerSet) {
          this.showErrorMessage("trying to reconnect...");
        }
        this.v = null;
        if (this.b != null) {
          this.b.abort();
        }
        this.b = null;
        this.m = null;
        this.v = null;
        this.isPlayerSet = false;
        if (this.isJpeg) {
          var i = document.getElementById('${this.elId}_img');
          i?.remove();
        } else {
          var v = document.getElementById('${this.elId}_video');
          v?.remove();
        }
        Future.delayed(Duration(seconds: 1), () {
          this.play();
        });
      }
    });
    this.v.onMessage.listen((e) {
      switch (e.data) {
        case "Init":
          var errMsg = "Player is not initialized. Please call InitPlayer() first!!";
          if (this.errorCallback != null) {
            this.errorCallback!(errMsg);
          }
          this.showErrorMessage(errMsg);
          return;
        case "EmptyUrl":
          var errMsg = this.mode == "Live" ? "Url not configured" : "Recording not found";
          if (this.errorCallback != null) {
            this.errorCallback!(errMsg);
          }
          this.showErrorMessage(errMsg);
          return;
        case "retrying":
          if (this.retryingCallback != null) {
            this.retryingCallback!();
          }
          this.showErrorMessage("trying to reconnect...");
          try {
            if (this.b != null && this.b.buffered != null) {
              var start = this.b.buffered.start(0);
              var end = this.b.buffered.end(0);
              this.b.remove(start, end);
            }
          } catch (ex) {
            print(ex);
          }
          return;
        case "License Expired":
          var errMsg = "License Expired/Invalid";
          if (this.errorCallback != null) {
            this.errorCallback!(errMsg);
          }
          this.showErrorMessage(errMsg);
          return;
        case "Some problem occured":
          var errMsg = "Some problem occured";
          if (this.errorCallback != null) {
            this.errorCallback!(errMsg);
          }
          this.showErrorMessage(errMsg);
          return;
        default:
          this.removeErrorMessage();
      }
      if (!this.isPlayerSet) {
        if (e.data is Uint8List) {
          return;
        } else {
          if (e.data == "mp4") {
            this.removeErrorMessage();
            this.v = VideoElement();
            var div = document.getElementById(this.elId);
            div!.style.background = "black";
            div.append(this.v);
            this.v.id = '${this.elId}_video';
            this.v.src = Url.createObjectUrlFromBlob(this.m);
            this.v.controls = true;
            this.v.autoplay = true;
            this.v.style.width = "100%";
            this.isPlayerSet = true;
            this.isJpeg = false;
          } else {
            this.removeErrorMessage();
            var div = document.getElementById(this.elId);
            div!.style.background = "black";
            var img = ImageElement();
            div.append(img);
            img.id = '${this.elId}_img';
            img.style.width = "100%";
            img.style.height = "100%";
            this.isPlayerSet = true;
            this.isJpeg = true;
          }
        }
      }
      if (this.isJpeg) {
        var img = document.getElementById('${this.elId}_img') as ImageElement;
        if (e.data is Uint8List) {
          var arr = e.data;
          var base64String = this.arrayBufferToBase64(arr);
          img!.src = 'data:image/jpeg;base64,$base64String';
        }
      } else {
        if (e.data is Uint8List) {
          var intS = e.data;
          if (!this.isSourceReady) {
            this.intS = intS;
            return;
          }
          if (!this.b.updating && this.m.readyState == 'open') {
            this.b.appendBuffer(intS);
          } else {
            this.lastSegment = intS;
          }
        }
      }
    });
    this.v.onError.listen((event) {
      print(event);
      var errMsg = "Websocket connection failed. Please check if player is running.";
      this.showErrorMessage(errMsg);
      if (this.errorCallback != null) {
        this.errorCallback!(errMsg);
      }
    });
  }

  void showErrorMessage(String errMsg) {
    var eDiv = document.getElementById('${this.elId}_error');
    if (eDiv == null) {
      eDiv = DivElement();
      eDiv.id = '${this.elId}_error';
      eDiv.style.color = "white";
      var div = document.getElementById(this.elId);
      div!.append(eDiv);
    }
    eDiv.text = errMsg;
  }

  void removeErrorMessage() {
    var eDiv = document.getElementById('${this.elId}_error');
    eDiv?.remove();
  }
}

void main() {
  var controller = WebLiveController("playerIP", "serverIp", "playerId", "cameraId");
}
