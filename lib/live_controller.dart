// class WebLiveController {
//    webLiveController(String playerIP, String serverIp, String playerId, String cameraId) {
//     // Your implementation here
//     // print("webLiveController method called with $arg1, $arg2, $arg3, $arg4");


//    print(playerIP+serverIp+playerId+cameraId);
//     var playerObj;
//     print("in Js" +cameraId);
//     // var streamtype = "0";
//     // console.log(streamtype)

//     // var serverIp = "192.168.0.48"; //This is Ip of Player Server Module (Same as VMS if player server installed on same machine)
//     var sdk = new I2vSdk(playerIP, serverIp, false, 8890);

//     // //create new player object, video will start automatically
//     playerObj = sdk.GetLivePlayer(playerId, cameraId, "0", "0", "");

//     //set Error callback for play method
//     playerObj.setErrorCallback( (err) {
//         print(err);
//     });

//     //set retrying callback
//     playerObj.setRetryingCallback( (err) {
//         print("disconnected, retrying to connect!!");
//     });

//     playerObj.stop( () {
//         print("stop called!!!");
//     });

//     //call play method
//     // playerObj.play();
//     // console.log("In Live_Play");
//     // console.log(playerObj);
//     return playerObj;
//   }
// }