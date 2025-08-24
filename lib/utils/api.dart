import 'package:dio/dio.dart';
import 'package:ys_app/models/home.dart';
import 'package:ys_app/utils/config.dart';

class Api {
  static final _dio = Dio();

  static Future<HomeData> fetchHomeData() async {
    try {
      final res = await _dio.get('${AppConfigs.apiBaseUrl}/api/video');
      return HomeData.fromJson(res.data);
    } on DioException catch (e) {
      // 网络/域名/端口错误
      throw '网络异常，请确认服务已启动且地址正确：${e.message}';
    } catch (e) {
      throw '解析失败：$e';
    }
  }

  static Future<List<String>> fetchSearchData(String keyword) async {
    try {
      final res = await _dio
          .get('${AppConfigs.apiBaseUrl}/api/search', queryParameters: {
        'keyword': keyword,
      });
      return (res.data as List)
          .map<String>((e) => e['name'] as String)
          .toList();
    } on DioException catch (e) {
      // 网络/域名/端口错误
      throw '网络异常，请确认服务已启动且地址正确：${e.message}';
    } catch (e) {
      throw '解析失败：$e';
    }
  }

  static Future<VideoData> fetchVideoData(String name) async {
    try {
      final res = await _dio
          .get('${AppConfigs.apiBaseUrl}/api/video', queryParameters: {
        'name': name,
      });
      return VideoData.fromJson(res.data);
    } on DioException catch (e) {
      // 网络/域名/端口错误
      throw '网络异常，请确认服务已启动且地址正确：${e.message}';
    } catch (e) {
      throw '解析失败：$e';
    }
  }
}
