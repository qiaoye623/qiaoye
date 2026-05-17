import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:crypto/crypto.dart';

class ActivationService {
  static const _storageKey = '_am_activated';
  // 密钥（必须与 server/generate_code.py 中的 SECRET_KEY 一致）
  static const _secretKey = 'AomenMa2026SecretKey!@#';

  /// 检查当前设备是否已激活
  static bool checkActivated() {
    try {
      final val = html.window.localStorage[_storageKey];
      return val != null && val.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 验证并激活
  /// 返回 (成功, 错误信息)
  static (bool, String) activate(String code) {
    final cleaned = code.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (cleaned.length != 18) {
      return (false, '激活码格式不正确，请输入 AM-XXXXXXXX-XXXXXXXX 格式的激活码');
    }
    if (!cleaned.startsWith('AM')) {
      return (false, '激活码必须以 AM 开头');
    }

    final serial = cleaned.substring(2, 10);
    final sig = cleaned.substring(10, 18);
    final payload = 'AM$serial';

    // HMAC-SHA256 验证
    final hmacSha256 = Hmac(sha256, _secretKey.codeUnits);
    final digest = hmacSha256.convert(payload.codeUnits);
    final expected = digest.toString().substring(0, 8).toUpperCase();

    if (sig != expected) {
      return (false, '激活码无效，请检查后重试');
    }

    // 写入 localStorage
    final record = jsonEncode({
      'code': code,
      'serial': serial,
      'activated_at': DateTime.now().toIso8601String(),
    });
    html.window.localStorage[_storageKey] = record;

    return (true, '激活成功！');
  }

  /// 清除激活状态（调试用）
  static void deactivate() {
    try {
      html.window.localStorage.remove(_storageKey);
    } catch (_) {}
  }
}
