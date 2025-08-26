import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ys_app/play.dart';
import 'package:ys_app/utils/api.dart';
import 'models/home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<HomeData> _homeDataFuture;
  // 数据
  List<VideoItem> _hot = [];
  List<VideoItem> _latest = [];

  // 搜索过滤
  List<String> _filter = [];
  OverlayEntry? _overlayEntry;
  Timer? _debounce;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focus = FocusNode();
  final GlobalKey _searchKey = GlobalKey();

  _showOverlay() {
    _hideOverlay(); // 先清理旧 Overlay

    // 先在当前帧拿到搜索框的 RenderBox
    final renderBox =
        _searchKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero); // 左上角坐标
    final bottomY = offset.dy + renderBox.size.height; // 底边 y

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: bottomY + 4, // 搜索框下方
        left: 12,
        right: 12,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filter.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(_filter[i]),
                onTap: () {
                  _hideOverlay();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayPage(_filter[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void initState() {
    super.initState();

    // 拉取首页数据
    _homeDataFuture = Api.fetchHomeData();

    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400),
          () => _onSearch(_searchController.text.trim()));
    });

    // 点击外部关闭 Overlay
    _focus.addListener(() {
      if (!_focus.hasFocus) _hideOverlay();
    });
  }

  void _onSearch(String key) async {
    if (key.isEmpty) {
      _hideOverlay();
      return;
    }
    try {
      final data = await Api.fetchSearchData(key);
      debugPrint('搜索成功: ${data.toString()}');
      setState(() {
        _filter = data;
      });
    } catch (error) {
      debugPrint('搜索失败: $error');
      setState(() {
        _filter = [];
      });
    } finally {
      if (_filter.isNotEmpty) {
        _showOverlay();
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focus.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('影视搜索'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<HomeData>(
        future: _homeDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('正在加载数据...'),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 40, color: Colors.redAccent),
                    SizedBox(height: 10),
                    Text('数据加载失败', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            );
          } else {
            final homeData = snapshot.data!;
            debugPrint('首页数据: ${homeData.toJson()}');
            _hot = homeData.hotList;
            _latest = homeData.newList;
            return Padding(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 搜索框
                    TextField(
                      key: _searchKey,
                      focusNode: _focus,
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '请输入影片名称...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 热门推荐
                    _buildTitle('热门推荐', Colors.redAccent),
                    _buildTitleList(_hot),

                    const SizedBox(height: 20),

                    // 最新上线
                    _buildTitle('最新上线', Colors.blueAccent),
                    _buildTitleList(_latest),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTitle(String title, Color activeColor) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: activeColor),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            )),
      ],
    );
  }

  Widget _buildTitleList(List<VideoItem> items) {
    return GridView.count(
      shrinkWrap: true, // 内容多高控件就多高
      physics: const NeverScrollableScrollPhysics(), // 禁止滚动
      padding: const EdgeInsets.only(top: 10, left: 5, right: 5, bottom: 0),
      crossAxisCount: 2, // 每行 2 个
      childAspectRatio: 6, // 宽:高 ≈ 6:1（文字行）
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: items
          .map(
            (item) => InkWell(
              onTap: () {
                debugPrint('点击影视 :${item.toJson()}');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayPage(
                      item.name,
                      episode: item.eps.isNotEmpty ? item.eps.first.name : null,
                      playUrl: item.eps.isNotEmpty ? item.eps.first.url : null,
                    ),
                  ),
                );
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
