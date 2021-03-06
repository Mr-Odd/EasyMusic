/*
 * @Creator: Odd
 * @Date: 2022-02-07 02:57:32
 * @LastEditTime: 2022-02-28 02:54:12
 * @FilePath: \flutter_music_player\lib\models\user.dart
 */
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
//用户
class User with ChangeNotifier {
  String uname = '---';
  num id = -1;
  String avatarUrl = '';
  String cookie = '';
  bool isLogin = false;
  String backgroundUrl = '';

  User();

  User.init(this.uname, this.id, this.avatarUrl, this.cookie, this.isLogin,
      this.backgroundUrl);


  User.fromJson(Map<String, dynamic> json)
      : id = json['account']['id'],
        uname = json['profile']['nickname'],
        avatarUrl = json['profile']['avatarUrl'],
        cookie = json['cookie'],
        isLogin = true,
        backgroundUrl = json['profile']['backgroundUrl'];
  
  ///保存创建者信息
  User.fromJson2(Map<dynamic, dynamic> json)
      : id = json['userId'],
        uname = json['nickname'],
        avatarUrl = json['avatarUrl'];

  Map<String, Object> toJson() => <String, Object>{
        'nickname': uname,
        'userId': id,
        'avatarUrl': avatarUrl,
        'cookie': cookie,
        'isLogin': isLogin,
        'backgroundUrl': backgroundUrl
      };

  updateUser(User user) {
    //更新user信息
    uname = user.uname;
    id = user.id;
    avatarUrl = user.avatarUrl;
    cookie = user.cookie;
    isLogin = user.isLogin;
    backgroundUrl = user.backgroundUrl;
    notifyListeners();
  }

  @override
  String toString() {
    return 'User{uname: $uname, id: $id, avatarUrl: $avatarUrl, cookie: $cookie, isLogin: $isLogin, backgroundUrl: $backgroundUrl}';
  }
}
