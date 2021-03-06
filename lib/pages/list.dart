import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_music_player/models/album.dart';
import 'package:flutter_music_player/models/artist.dart';
import 'package:flutter_music_player/models/play_list.dart';
import 'package:flutter_music_player/models/song.dart';
import 'package:flutter_music_player/models/user.dart';
import 'package:flutter_music_player/pages/search.dart';
import 'package:flutter_music_player/utils/audio_player_manager.dart';
import 'package:flutter_music_player/utils/http_manager.dart';
import 'package:flutter_music_player/widgets/playlist_details.dart';
import 'package:flutter_music_player/widgets/bottom_player_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:sp_util/sp_util.dart';
import 'package:transparent_image/transparent_image.dart';

class PlayListPage extends StatefulWidget {
  final String title;

  final PlayList playList;

  const PlayListPage({Key? key, required this.playList, required this.title})
      : super(key: key);

  @override
  _PlayListPageState createState() => _PlayListPageState();
}

class _PlayListPageState extends State<PlayListPage> {
  List<UriAudioSource> _songs = [];
  late final HttpManager _httpManager;

  late final AudioPlayerManager _playerManager;

  final _token = CancelToken();

  bool firstPlay = true; // 是否是第一次播放

  //获取歌单中的歌曲
  _getPlayListSongs() async {
    bool? isCached = SpUtil.haveKey('playListSongs${widget.playList.id}');
    if (isCached == true) {
      //从缓存中获取
      var s = SpUtil.getObjList<UriAudioSource>(
          'playListSongs${widget.playList.id}', (v) {
        List<Artist> artists =
            v['artist'].map<Artist>((e) => Artist.fromJson(e))?.toList();
        final tmp = Song.fromJson(v, artists, Album.fromJson(v['album']));
        return AudioSource.uri(
            Uri.parse(
                'https://music.163.com/song/media/outer/url?id=${tmp.id}.mp3'),
            tag: tmp);
      })!;
      setState(() {
        _songs = s;
      });
    } else {
      //从网络获取
      try {
        var data = await _httpManager.get(
            '/playlist/detail?id=${widget.playList.id}&cookie=${context.read<User>().cookie}',
            cancelToken: _token);
        if (data != null && data['code'] == 200) {
          final List<Song> tmpList = [];
          setState(() {
            _songs = data['playlist']['tracks'].map<UriAudioSource>((e) {
              final Album al = Album.fromJson(e['al']);
              final List<Artist> ar =
                  e['ar'].map<Artist>((v) => Artist.fromJson(v)).toList();
              final tmp = Song.fromJson(e, ar, al);
              tmpList.add(tmp);
              return AudioSource.uri(
                  Uri.parse(
                      'https://music.163.com/song/media/outer/url?id=${tmp.id}.mp3'),
                  tag: tmp);
            }).toList();
            //缓存
            SpUtil.putObjectList('playListSongs${widget.playList.id}', tmpList);
          });
        }
      } catch (e) {
        print(e);
      }
    }
  }

  //播放歌曲
  playMusic(i) async {
    if (firstPlay) {
      await _playerManager.playlist.clear().then((value) => _playerManager.playlist
          .addAll(_songs)
          .then((value) => _playerManager.play(index: i)));
      firstPlay = false;
    } else {
      _playerManager.play(index: i);
    }
  }

  @override
  void initState() {
    super.initState();
    _httpManager = HttpManager.getInstance();
    _playerManager = AudioPlayerManager.getInstance()!;
    _getPlayListSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            // 滑动到顶端时会固定住
            stretch: true,
            title: Text(
              widget.title,
              style: const TextStyle(color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (context) {
                        return const SearchPage();
                      }),
                    );
                  },
                  icon: const Icon(Icons.search_rounded)),
            ],
            expandedHeight: 320.0,
            flexibleSpace: FlexibleSpaceBar(
                background: Stack(
              alignment: Alignment.center,
              children: [
                FadeInImage.memoryNetwork(
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                  image: widget.playList.coverImgUrl,
                  placeholder: kTransparentImage,
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                PlaylistDetails(
                  playlistInfo: widget.playList,
                ),
              ],
            )),
          ),
          _songs.isEmpty
              ? const SliverToBoxAdapter(
                  child: LinearProgressIndicator(),
                )
              : SliverPrototypeExtentList(
                  delegate: SliverChildBuilderDelegate(
                      (c, i) => ListTile(
                            onTap: () {
                              //播放歌曲
                              playMusic(i);
                            },
                            title: Text(
                              _songs[i].tag.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: SizedBox(
                              child: Center(
                                  child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 20),
                              )),
                              height: 50,
                              width: 50,
                            ),
                            subtitle: Text(_songs[i].tag.showArtist()),
                          ),
                      childCount: _songs.length),
                  prototypeItem: const ListTile(
                    title: Text(''),
                    subtitle: Text(''),
                    leading: Icon(Icons.print_rounded),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: const BottomPlayerBar(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _httpManager.cancelRequest(_token);
  }
}
