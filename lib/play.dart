import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
  late VideoPlayerController _playerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    initializeVideo(widget.playUrl); // 把初始化逻辑拆出去，方便用 async/await
  }

  Future<void> initializeVideo(String playUrl) async {
    // 初始化 VideoPlayerController，这里使用 m3u8 链接
    _playerController = VideoPlayerController.networkUrl(
      Uri.parse(playUrl),
    );
    // 添加监听器以捕获错误
    _playerController.addListener(() {
      if (_playerController.value.hasError) {
        debugPrint('播放错误: ${_playerController.value.errorDescription}');
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
        aspectRatio: _playerController.value.aspectRatio,
        errorBuilder: (context, error) => Center(
          child:
              Text('播放失败: $error', style: const TextStyle(color: Colors.red)),
        ),
      );
      setState(() {}); // ✅ 初始化完成后刷新界面
    } catch (e) {
      debugPrint('初始化失败: $e');
    }
  }

  @override
  void dispose() {
    _playerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Video Player'),
      // ),
      body: Center(
        child: _playerController.value.isInitialized
            ? Chewie(
                controller: _chewieController,
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
