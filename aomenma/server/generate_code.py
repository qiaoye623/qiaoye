"""
激活码生成工具
用法: python server/generate_code.py
输出: AM-XXXXXXXX-XXXXXXXX 格式的激活码
"""

import hashlib
import hmac
import secrets

# ===== 密钥（必须与 activation_service.dart 中的 _secretKey 一致）=====
SECRET_KEY = b'AomenMa2026SecretKey!@#'


def generate_code() -> str:
    """生成一个 HMAC 签名激活码"""
    # 8位随机序列号
    serial = secrets.token_hex(4).upper()
    payload = f"AM{serial}"

    # HMAC-SHA256 签名，取前8位
    sig = hmac.new(SECRET_KEY, payload.encode(), hashlib.sha256).hexdigest()[:8].upper()

    code = f"AM-{serial}-{sig}"
    return code


if __name__ == '__main__':
    code = generate_code()
    print(f"激活码: {code}")
    print(f"共 {len(code)} 字符")
    print()
    input("按 Enter 键退出...")
