import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ys_app/utils/config.dart';

class DialogHelper {
  static Future<String?> showUrlInput(BuildContext context) async {
    final urlController = TextEditingController(text: AppConfigs.apiBaseUrl);
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // 禁止点外部关闭
      builder: (_) => PopScope(
        canPop: false, // 阻止返回按钮关闭弹框
        child: AlertDialog(
          title: const Text('请输入服务器地址'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: '请输入有效的 URL'),
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
              onPressed: () =>
                  Navigator.pop(context, urlController.text.trim()),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showAlert(BuildContext context, String message,
      {VoidCallback? onComfirm, String dialogTitle = "警告"}) async {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          dialogTitle,
          textAlign: TextAlign.center,
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (onComfirm != null) {
                onComfirm();
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  static Future<void> showError(BuildContext context, String message,
      {VoidCallback? onComfirm, String dialogTitle = "错误"}) async {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          dialogTitle,
          textAlign: TextAlign.center,
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (onComfirm != null) {
                onComfirm();
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  static Future<void> showSnackBar(BuildContext context, String message,
      {VoidCallback? onClosed, Color? backgroundColor = Colors.red}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: backgroundColor, // 设置背景颜色
      ),
    );
    if (onClosed != null) {
      onClosed();
    }
  }
}
