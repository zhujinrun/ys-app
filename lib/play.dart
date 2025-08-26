import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ys_app/utils/api.dart';
import 'package:ys_app/models/home.dart';
import 'package:ys_app/utils/dialog.dart';

class PlayPage extends StatefulWidget {
  /// 影视名称
  final String name;

  /// 剧集年份（可选）
  final String year;

  /// 影视源（可空）
  final List<Episode> eps;

  /// 构造器
  const PlayPage(this.name, {super.key, this.year = "", this.eps = const []});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  // 数据
  String _year = '';
  String _type = '';
  String _playUrl = '';

  int _sourceIndex = 0;
  List<VideoItem> _sources = [];
  int _epIndex = 0;
  List<Episode> _eps = [];

  late Future<void> _playerFuture;
  late VideoPlayerController _playerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();

    debugPrint('准备播放: ${widget.name}');
    _eps = widget.eps;
    _type = widget.eps.isNotEmpty ? '电影' : '连续剧';
    _year = widget.year;

    debugPrint('eps: ${_eps.length} ${_eps.isNotEmpty}');
    if (_eps.isNotEmpty) {
      _sources = [VideoItem(name: widget.name, year: widget.year, eps: _eps)];
      _playUrl = _eps.first.url;
      debugPrint('当前播放地址: $_playUrl');
      _playerFuture = initializeVideo(_playUrl);
    } else {
      _playerFuture = fetchVideoByName(widget.name);
    }

    WakelockPlus.enable(); // 启用屏幕常亮
  }

  Future<void> playSource({int index = 0}) async {
    debugPrint('正在播放源：$index');
    _eps = _sources[index].eps;
    _year = _sources[index].year;
    await initializeVideo(_sources[index].eps.first.url);
  }

  Future<void> changeSource() async {
    _sourceIndex++;
    if (_sourceIndex >= _sources.length) {
      _sourceIndex = 0;
    }
    await playSource(index: _sourceIndex);
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
        DialogHelper.showSnackBar(context, '视频播放错误');
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
          playbackSpeedButtonText: '倍速',
          subtitlesButtonText: '字幕',
          cancelButtonText: '取消',
        ),
        additionalOptions: (context) {
          return <OptionItem>[
            _sources.length > 1
                ? OptionItem(
                    onTap: (context) {
                      // debugPrint('点击了换源!');
                      DialogHelper.showSnackBar(context, '正在换源...');
                      changeSource();
                      Navigator.of(context).pop(); // 关闭底部弹出
                    },
                    iconData: Icons.sync,
                    title: '换源',
                  )
                : OptionItem(
                    onTap: (context) {
                      // debugPrint('点击了重试!');
                      DialogHelper.showSnackBar(context, '正在重试...');
                      playSource();
                      Navigator.of(context).pop(); // 关闭底部弹出
                    },
                    iconData: Icons.restart_alt_outlined,
                    title: '重试',
                  )
          ];
        },
        // aspectRatio: _playerController.value.aspectRatio,
        errorBuilder: (context, error) {
          return Scaffold(
            body: GestureDetector(
              onTap: () async {
                // 处理点击事件
                if (_sources.length > 1) {
                  await DialogHelper.showSnackBar(context, '正在换源...');
                  await changeSource();
                } else {
                  await DialogHelper.showSnackBar(context, '正在重试...');
                  await playSource();
                }
              },
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.redAccent),
                    const SizedBox(height: 10),
                    Text(
                      _sources.length > 1 ? '视频播放出错，点击刷新重试' : '视频播放出错，点击尝试换源',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      // 加载完立即播放
      _playerController.play();
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
      _sources = data.data;
      if (data.type == 'movie') {
        _type = '电影';
        // 处理电影类型
        if (_sources.isNotEmpty) {
          await playSource();
          // setState(() {});
        } else {
          debugPrint('没有找到任何电影: ${data.toJson()}');
        }
      } else if (data.type == 'tv') {
        _type = '连续剧';
        // 处理电视剧类型
        if (_sources.isNotEmpty) {
          await playSource();
          // setState(() {});
        } else {
          debugPrint('没有找到任何剧集: ${data.toJson()}');
        }
      } else {
        _type = '未知';
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
          return Scaffold(
            body: GestureDetector(
              onTap: () async {
                // 处理点击事件
                if (_sources.length > 1) {
                  await DialogHelper.showSnackBar(context, '正在换源...');
                  await changeSource();
                } else {
                  await DialogHelper.showSnackBar(context, '正在重试...');
                  await playSource();
                }
              },
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.redAccent),
                    const SizedBox(height: 10),
                    Text(
                      _sources.length > 1 ? '视频播放出错，点击刷新重试' : '视频播放出错，点击尝试换源',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
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
                          text: widget.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                        const TextSpan(text: '      '),
                        if (_type.isNotEmpty) ...[
                          const TextSpan(text: '类型: '),
                          TextSpan(
                            text: _type,
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
                    child: _eps.isNotEmpty
                        ? _buildEpisodeList(_eps)
                        : const SizedBox.shrink()),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildEpisodeList(List<Episode> eps) {
    return GridView.builder(
      shrinkWrap: true, // 内容多高控件就多高
      // physics: const NeverScrollableScrollPhysics(), // 禁止滚动
      padding: const EdgeInsets.all(5),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 每行 4 个
        childAspectRatio: 3, // 宽:高 ≈ 3:1（文字行）
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: eps.length,
      itemBuilder: (context, index) {
        final item = eps[index];
        return InkWell(
          onTap: () {
            debugPrint('点击影视 :${item.toJson()}');
            _epIndex = index; // 直接用 index，无需 indexOf
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _epIndex == index ? Colors.blue.shade700 : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
