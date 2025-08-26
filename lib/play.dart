import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ys_app/utils/api.dart';
import 'package:ys_app/models/home.dart';
import 'package:ys_app/utils/dialog.dart';

class PlayPage extends StatefulWidget {
  /// 影视名称
  final String title;

  /// 剧集标题（可选）
  final String? episode;

  /// m3u8 播放地址
  final String? playUrl;

  /// 构造器
  const PlayPage(this.title, {super.key, this.episode, this.playUrl});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  // 数据
  String _episode = '';
  String _playUrl = '';
  String _year = '';
  List<Episode> eps = [];

  late Future<void> _playerFuture;
  late VideoPlayerController _playerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    debugPrint('正在播放: ${widget.title}');
    debugPrint('播放剧集: ${widget.episode}');
    debugPrint('播放地址: ${widget.playUrl}');
    _episode = widget.episode ?? '';
    _playUrl = widget.playUrl ?? '';

    if (_playUrl.isNotEmpty) {
      _playerFuture = initializeVideo(_playUrl);
    } else {
      _playerFuture = fetchVideoByName(widget.title);
    }

    WakelockPlus.enable(); // 启用屏幕常亮
  }

  Future<void> initializeVideo(String playUrl) async {
    _playUrl = playUrl;
    // 初始化 VideoPlayerController，这里使用 m3u8 链接
    _playerController = VideoPlayerController.networkUrl(
      Uri.parse(_playUrl),
      // videoPlayerOptions: VideoPlayerOptions(
      //   webOptions: const VideoPlayerWebOptions(
      //     controls: VideoPlayerWebOptionsControls.enabled(),
      //   ),
      // ),
    );
    // 添加监听器以捕获错误
    _playerController.addListener(() {
      if (_playerController.value.hasError) {
        debugPrint('播放错误: ${_playerController.value.errorDescription}');
        DialogHelper.showError(context, '视频播放错误', onComfirm: () {
          _playerController.pause();
        });
      }
    });
    try {
      await _playerController.initialize(); // 🔥关键一步
      // 初始化 ChewieController
      _chewieController = ChewieController(
        videoPlayerController: _playerController,
        autoPlay: false,
        looping: false,
        showControls: true,
        playbackSpeeds: [0.5, 0.75, 1, 1.25, 1.5, 2],
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue.shade700, // 已播放部分的颜色
          handleColor: Colors.blue.shade300, // 拖动柄的颜色
          backgroundColor: Colors.grey.shade400, // 背景颜色
          bufferedColor: Colors.blue.shade100, // 已缓冲部分的颜色
        ),
        optionsTranslation: OptionsTranslation(
          playbackSpeedButtonText: '播放速度',
          subtitlesButtonText: '字幕',
          cancelButtonText: '取消',
        ),
        // aspectRatio: _playerController.value.aspectRatio,
        errorBuilder: (context, error) => Center(
          child:
              Text('播放失败: $error', style: const TextStyle(color: Colors.red)),
        ),
      );
      setState(() {}); // ✅ 初始化完成后刷新界面
    } catch (e) {
      debugPrint('初始化失败: $e');
      _playerFuture = Future.error("视频初始化失败");
      setState(() {});
    }
  }

  Future<void> fetchVideoByName(String videoName) async {
    try {
      final data = await Api.fetchVideoData(videoName);
      debugPrint('视频数据: ${data.toJson()}');
      if (data.type == 'movie') {
        // 处理电影类型
        if (data.data.isNotEmpty) {
          final movieEpisode = data.data.first.eps.first;
          _episode = movieEpisode.name;
          _year = data.data.first.year;
          await initializeVideo(movieEpisode.url);
          // setState(() {});
        } else {
          debugPrint('没有找到任何电影: ${data.toJson()}');
        }
      } else if (data.type == 'tv') {
        // 处理电视剧类型
        if (data.data.isNotEmpty) {
          final firstEpisode = data.data.first.eps.first;
          _episode = firstEpisode.name;
          _year = data.data.first.year;
          eps = data.data.first.eps;
          await initializeVideo(firstEpisode.url);
          // setState(() {});
        } else {
          debugPrint('没有找到任何剧集: ${data.toJson()}');
        }
      } else {
        debugPrint('未知视频类型: ${data.toJson()}');
      }
    } catch (error) {
      debugPrint('获取视频数据失败: $error');
      _playerFuture = Future.error("视频数据获取失败");
      setState(() {});
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable(); // 禁用屏幕常亮
    _playerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return FutureBuilder<void>(
      future: _playerFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('正在加载视频...'),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          debugPrint('加载失败: ${snapshot.error}');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 40, color: Colors.redAccent),
                  SizedBox(height: 10),
                  Text('视频加载失败', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            body: Column(
              children: [
                Container(
                  color: Colors.black.withOpacity(0.95),
                  height: screenHeight / 2.95,
                  width: screenWidth,
                  child: _playerController.value.isInitialized
                      ? Chewie(
                          controller: _chewieController,
                        )
                      : const Center(
                          child: SizedBox(
                            width: 40, // 任意相等值
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3, // 可选：更细/更粗
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        const TextSpan(text: ' '),
                        const TextSpan(text: '正在播放: '),
                        TextSpan(
                          text: widget.title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const TextSpan(text: '      '),
                        if (_episode.isNotEmpty) ...[
                          const TextSpan(text: '剧集: '),
                          TextSpan(
                            text: _episode,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ],
                        const TextSpan(text: '      '),
                        if (_year.isNotEmpty) ...[
                          const TextSpan(text: '年份: '),
                          TextSpan(
                            text: _year,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                    child: eps.isNotEmpty
                        ? _buildEpisodeList(eps)
                        : const SizedBox.shrink()),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildEpisodeList(List<Episode> eps) {
    return GridView.count(
      shrinkWrap: true, // 内容多高控件就多高
      // physics: const NeverScrollableScrollPhysics(), // 禁止滚动
      padding: const EdgeInsets.all(5),
      crossAxisCount: 4, // 每行 4 个
      childAspectRatio: 3, // 宽:高 ≈ 3:1（文字行）
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: eps
          .map(
            (item) => InkWell(
              onTap: () {
                debugPrint('点击影视 :${item.toJson()}');
                setState(() {
                  _episode = item.name;
                });
                initializeVideo(item.url);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
