class DeviceBean {
  String id;
  String localName;
  String displayName;
  int deviceType;
  bool isBroadcast; //是否为广播蓝牙设备
  bool isConnected;
  bool enabled; //电源
  bool isChecked;
  int motorAModeNum; //电机A
  int motorBModeNum; //电机B
  int motorCModeNum; //电机C
  int motorNum; //电机数量
  bool isLight; //灯光
  bool isPlaying; //声音播放
  String helperId; //合作商ID / 网易IM聊天ID
  String extra;
  DeviceBean(
      {required this.id,
      required this.localName,
      required this.displayName,
      required this.deviceType,
      this.isBroadcast = false,
      this.isConnected = false,
      this.enabled = false,
      this.isChecked = false,
      this.isLight = false,
      this.isPlaying = false,
      this.motorAModeNum = 0,
      this.motorBModeNum = 0,
      this.motorCModeNum = 0,
      this.motorNum = 0,
      this.helperId = "",
      this.extra = ''});

  factory DeviceBean.fromJson(Map<String, dynamic> json) => DeviceBean(
      id: json["id"],
      localName: json["localName"]??"",
      displayName: json["displayName"],
      deviceType: json["deviceType"],
      isBroadcast: json["isBroadcast"]??false,
      isConnected: json["isConnected"]??false,
      enabled: json["enabled"]??false,
      isChecked: json["isChecked"]??false,
      isLight: json["isLight"]??false,
      isPlaying: json["isPlaying"]??false,
      motorAModeNum: json["motorAModeNum"]??0,
      motorBModeNum: json["motorBModeNum"]??0,
      motorCModeNum: json["motorCModeNum"]??0,
      motorNum: json["motorNum"]??0,
      extra: json["extra"]??"",
      helperId: json["helperId"]??"");

  Map<String, dynamic> toJson() => {
        "id": id,
        "localName": localName,
        "displayName": displayName,
        "deviceType": deviceType,
        "isBroadcast": isBroadcast,
        "isConnected": isConnected,
        "enabled": enabled,
        "isChecked": isChecked,
        "isLight": isLight,
        "isPlaying": isPlaying,
        "helperId": helperId,
        "extra": extra,
        "motorAModeNum": motorAModeNum,
        "motorBModeNum": motorBModeNum,
        "motorCModeNum": motorCModeNum,
        "motorNum": motorNum,
      };
}
