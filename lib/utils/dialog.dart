import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ys_app/utils/config.dart';

class DialogHelper {
  static Future<String?> showUrlInput(BuildContext context) async {
    final urlController = TextEditingController(text: AppConfigs.apiBaseUrl);
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // 禁止点外部关闭
      builder: (_) => AlertDialog(
        title: const Text('请输入服务器地址'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: 'http://ip:port'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 退出应用
              SystemNavigator.pop(); // Android
              // exit(0);            // 如需 iOS/MacOS 可用
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, urlController.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
