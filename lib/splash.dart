import 'package:flutter/material.dart';
import 'package:ys_app/home.dart';
import 'package:ys_app/utils/api.dart';
import 'package:ys_app/utils/config.dart';
import 'package:ys_app/utils/dialog.dart';
import 'package:ys_app/utils/sputil.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
    });
  }

  Future<void> _checkFirstRun() async {
    bool isFirstRun =
        await SpUtil.getBool(AppConfigs.appFirstRun, defaultValue: true);
    String serverUrl = await SpUtil.getString(AppConfigs.appServer);
    if (isFirstRun || serverUrl.isEmpty) {
      // 如果是首次启动或没有保存的 URL，显示输入对话框
      await _showUrlInputDialog();
    } else {
      // 如果不是首次启动，检查保存的 URL 是否有效
      bool isHealth = await Api.checkHealth(serverUrl);
      if (!isHealth) {
        // 如果保存的 URL 无效，提示用户重新输入
        await _showUrlInputDialog();
      } else {
        // 如果保存的 URL 有效，直接跳转到首页
        AppConfigs.apiBaseUrl = serverUrl;
        _navigateToHome();
      }
    }
  }

  Future<void> _showUrlInputDialog() async {
    String? url;
    bool isHealth = false;
    while (!isHealth) {
      if (mounted) {
        url = await DialogHelper.showUrlInput(context);
      }
      if (url == null) {
        // 如果用户取消输入，退出循环
        await SpUtil.setBool(AppConfigs.appFirstRun, true);
        break;
      }
      isHealth = await Api.checkHealth(url);
      // 如果 URL 不健康，提示用户重新输入
      if (!isHealth) {
        if (mounted) {
          DialogHelper.showSnackBar(context, "服务器地址加载失败，请重新输入");
        }
      }
    }
    if (isHealth) {
      AppConfigs.apiBaseUrl = url!;
      await SpUtil.setString(AppConfigs.appServer, url);
      // 记录应用已经启动过
      await SpUtil.setBool(AppConfigs.appFirstRun, false);
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    // 确保在正确的上下文中调用 Navigator
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('正在加载配置...'),
          ],
        ),
      ),
    );
  }
}
