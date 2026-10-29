# WinRelay 本机工具链与构建(2026-10-29 搭建)

## 已就绪的工具链

| 工具 | 版本 | 位置 |
| --- | --- | --- |
| Rust | 1.95.0 | rustup 默认 |
| Flutter | 3.47.8 stable | `C:\Android\flutter`(已加入用户 PATH) |
| Android SDK | 36 + build-tools 36.0.0 | `C:\Android\sdk`(`ANDROID_HOME`) |
| JDK | 21.0.12 | `C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot` |

- Flutter 镜像:`PUB_HOSTED_URL=https://pub.flutter-io.cn`、`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
- Gradle 代理:已写入 `mobile/android/gradle.properties`(Clash 127.0.0.1:7897)
- 注意:C 盘根目录不可写,SDK 一律放 `C:\Android` 下;Git Bash 直接跑 `flutter.bat`/`dart.bat`,复杂 PowerShell 逻辑写成 .ps1 文件执行(`$_`/`$p` 会被 bash 吞)

## 构建 host(Rust)

```
cd host
cargo build --release        # 产物 target\release\winrelay-host.exe
```

2026-10-29:debug 与 release 均一次通过,仅 2 个无害 dead-code 警告
(`Viewport::dpr`、`Session::stealth` 字段暂未读)。

### 冒烟与端到端

```
host\target\release\winrelay-host.exe   # 打开 http://localhost:47800/ui
python host/tests/e2e_pair_list.py      # WS 配对→批准→拉窗口列表,只读无副作用
```

E2E 已验证:hello(token)→ pending → /api/approve → approved(40 位 secret)
→ welcome → list(27 个真实窗口);错误 secret 被拒;设备落盘 config.json;
配对 token 一次性轮换。测完已把设备清空、换新 token。

## 构建手机端(Flutter)

工程即 `mobile/`(android 骨架由 `flutter create --platforms android` 生成后并入)。

```
cd mobile
flutter pub get
flutter analyze          # 0 issue
flutter build apk        # 产物 build\app\outputs\flutter-apk\app-release.apk
```

`AndroidManifest.xml` 已按 README 加:INTERNET、CAMERA 权限,
`usesCleartextTraffic="true"`(MVP 用 ws://),应用名 WinRelay。

## 已知待办(对应 README Roadmap)

1. TLS + 证书固定(上外网前必须)
2. WGC 采集 + WebRTC 替代 JPEG-over-WS
3. 托盘图标
4. 虚拟显示器驱动未安装 → 隐身模式暂不可用(非隐身控制不受影响)
