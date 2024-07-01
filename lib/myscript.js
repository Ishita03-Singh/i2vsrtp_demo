
function webLiveController(playerIP, serverIp, playerId, cameraId) {
    console.log(playerIP+serverIp+playerId+cameraId);
    var playerObj;
    console.log("in Js" +cameraId);
    // var streamtype = "0";
    // console.log(streamtype)

    // var serverIp = "192.168.0.48"; //This is Ip of Player Server Module (Same as VMS if player server installed on same machine)
    var sdk = new I2vSdk(playerIP, serverIp, false, 8890);

    //create new player object, video will start automatically
    playerObj = sdk.GetLivePlayer(playerId, cameraId, "0", "0", "");

    //set Error callback for play method
    playerObj.setErrorCallback(function (err) {
        console.error(err);
    });

    //set retrying callback
    playerObj.setRetryingCallback(function (err) {
        console.log("disconnected, retrying to connect!!");
    });

    playerObj.stop(function () {
        console.log("stop called!!!");
    });

    //call play method
    // playerObj.play();
    // console.log("In Live_Play");
    // console.log(playerObj);
    return playerObj;
}   

function Play_Live(serverIp, playerId, cameraId) {
    var playerObj;
    console.log(cameraId);

    // var serverIp = "192.168.0.48"; //This is Ip of Player Server Module (Same as VMS if player server installed on same machine)

    var sdk = new I2vSdk(serverIp, serverIp, false, 8890);

    //create new player object, video will start automatically
    playerObj = sdk.GetLivePlayer(playerId, cameraId, "0", "0", "");

    //set Error callback for play method
    playerObj.setErrorCallback(function (err) {
        console.error(err);
    });

    //set retrying callback
    playerObj.setRetryingCallback(function (err) {
        console.log("disconnected, retrying to connect!!");
    });

    playerObj.stop(function () {
        console.log("stop called!!!");
    });

    //call play method
    playerObj.play();
    console.log("In Live_Play");
    console.log(playerObj);
    return playerObj;
}   

function Play(playerObj) {
    console.log("In Play");
    playerObj.play();
}

function Stop(playerObj) {
    console.log("In Stop");
    playerObj.stop();
}

function Pause(playerObj) {
    console.log("In Pause");
    playerObj.Pause();
}

function Resume(playerObj) {
    console.log("In Resume");
    playerObj.Resume();
}
