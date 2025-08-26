class HomeData {
  final List<VideoItem> newList;
  final List<VideoItem> hotList;

  HomeData({required this.newList, required this.hotList});

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      newList: (json['new'] as List).map((e) => VideoItem.fromJson(e)).toList(),
      hotList: (json['hot'] as List).map((e) => VideoItem.fromJson(e)).toList(),
    );
  }

  /// 将对象序列化为 Map<String, dynamic>
  Map<String, dynamic> toJson() {
    return {
      'new': newList.map((e) => e.toJson()).toList(),
      'hot': hotList.map((e) => e.toJson()).toList(),
    };
  }
}

class VideoItem {
  final String name;
  final String year;
  final List<Episode> eps;

  VideoItem({required this.name, required this.year, required this.eps});

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    final src = json['source'] as Map<String, dynamic>? ?? {};
    final eps =
        (src['eps'] as List? ?? []).map((e) => Episode.fromJson(e)).toList();
    return VideoItem(name: json['name'], year: json['year'] ?? '', eps: eps);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'year': year,
      'source': {'eps': eps.map((e) => e.toJson()).toList()},
    };
  }
}

class Episode {
  final String name;
  final String url;

  Episode({required this.name, required this.url});

  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
        name: json['name'] ?? '',
        url: (json['url'] ?? '').toString().trim(),
      );

  Map<String, dynamic> toJson() => {'name': name, 'url': url};
}

class VideoData {
  final String type;
  final List<VideoItem> data;

  VideoData({required this.type, required this.data});

  factory VideoData.fromJson(Map<String, dynamic> json) => VideoData(
        type: json['type'] ?? '',
        data: (json['data'] as List).map((e) => VideoItem.fromJson(e)).toList(),
      );

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'ep': "1",
      'data': data.map((e) => e.toJson()).toList(),
      "y": []
    };
  }
}
