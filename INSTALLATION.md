# Flutter 安装和测试指南

## 第一步：安装Flutter SDK

### 方式一：手动下载安装（推荐）

1. **下载Flutter SDK**
   - 访问官网：https://docs.flutter.dev/get-started/install/windows
   - 点击下载最新稳定版（Flutter 3.24.5+）
   - 下载文件：`flutter_windows_3.24.5-stable.zip`

2. **解压到目录**
   - 解压到 `C:\src\flutter` 或 `D:\flutter`
   - ⚠️ 注意：路径中不要包含空格或特殊字符

3. **配置环境变量**
   - 打开"系统属性" → "高级" → "环境变量"
   - 在"系统变量"中找到 `Path`，点击"编辑"
   - 添加新条目：`D:\flutter\bin`（根据实际路径修改）
   - 点击"确定"保存

4. **验证安装**
   打开新的命令提示符或PowerShell，运行：
   ```bash
   flutter --version
   ```

   成功输出示例：
   ```
   Flutter 3.24.5 • channel stable
   Dart 3.5.3
   ```

### 方式二：使用包管理器（可选）

#### 使用 Chocolatey
```powershell
choco install flutter
```

#### 使用 Scoop
```powershell
scoop bucket add extras
scoop install flutter
```

## 第二步：运行环境检查

### 1. 运行 Flutter Doctor

```bash
flutter doctor
```

### 2. 解决常见问题

| 问题 | 解决方案 |
|------|---------|
| Android SDK not found | 安装 Android Studio |
| Visual Studio not installed | 安装 Visual Studio 2022（勾键"使用C++的桌面开发"） |
| Android license not accepted | 运行 `flutter doctor --android-licenses` |
| Device not found | 连接手机或启动模拟器 |

### 3. 最小安装要求

如果只想在浏览器中测试，只需要：
- ✅ Flutter SDK
- ✅ Chrome浏览器
- ✅ VSCode + Flutter扩展

## 第三步：安装VSCode扩展

1. 打开VSCode
2. 按 `Ctrl+Shift+X` 打开扩展商店
3. 搜索并安装：
   - **Flutter** (by Dart Code, Flutter Team)
   - **Dart** (by Dart Code, Flutter Team)

## 第四步：运行项目

### 方法一：在VSCode中运行

1. **打开项目**
   ```bash
   code d:\lxd\lixudong\myapp
   ```

2. **安装依赖**
   - 按 `Ctrl+Shift+P`
   - 输入 `Flutter: Get Packages`
   - 按回车执行

   或在终端中运行：
   ```bash
   flutter pub get
   ```

3. **选择设备**
   - 按 `F1` 或 `Ctrl+Shift+P`
   - 输入 `Flutter: Select Device`
   - 选择：
     - **Chrome**（Web浏览器，无需模拟器）
     - **Windows Desktop**（需要安装Visual Studio）
     - **Android Emulator**（需要安装Android Studio）

4. **运行应用**
   - 按 `F5` 或点击"运行"→"启动调试"
   - 或按 `Ctrl+F5` 不调试运行

### 方法二：使用命令行

```bash
# 进入项目目录
cd d:\lxd\lixudong\myapp

# 安装依赖
flutter pub get

# 运行（Web版，最简单）
flutter run -d chrome

# 或列出可用设备
flutter devices

# 然后选择设备运行
flutter run -d <device-id>
```

## 第五步：运行测试

### 1. 运行所有测试

```bash
flutter test
```

### 2. 运行特定测试文件

```bash
flutter test test/example_test.dart
```

### 3. 运行测试并查看覆盖率

```bash
flutter test --coverage
```

### 4. 查看测试报告

安装扩展后，可以查看HTML覆盖率报告：
```bash
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

## 常见问题解决

### 问题1：`flutter pub get` 失败

**原因**：网络问题或镜像未配置

**解决方案**：
```bash
# 使用国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 然后重新运行
flutter pub get
```

或在PowerShell中：
```powershell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

### 问题2：缺少`pubspec.yaml`依赖

如果出现依赖错误，检查 `pubspec.yaml` 中的依赖版本，然后运行：
```bash
flutter pub upgrade
```

### 问题3：Windows桌面运行失败

**解决方案**：
1. 安装 Visual Studio 2022
2. 安装"使用C++的桌面开发"工作负载
3. 重启电脑
4. 运行 `flutter doctor` 确认

### 问题4：代码分析错误

**解决方案**：
```bash
# 清理并重新获取依赖
flutter clean
flutter pub get

# 重启Dart分析服务器
# 在VSCode中：Ctrl+Shift+P → "Dart: Restart Analysis Server"
```

## 快速开始检查清单

安装完成后，按顺序检查：

- [ ] `flutter --version` 显示版本信息
- [ ] `flutter doctor` 无关键错误
- [ ] VSCode已安装Flutter扩展
- [ ] `flutter pub get` 成功运行
- [ ] `flutter test` 测试通过
- [ ] `flutter run -d chrome` 应用启动

## 测试输出示例

成功运行测试后，应该看到类似输出：

```
00:00 +0: TodoItem Tests
00:01 +1: All tests passed!
```

## 需要帮助？

如果遇到问题，可以：
1. 查看 `flutter doctor -v` 详细输出
2. 访问 Flutter中文网：https://flutter.cn/
3. 查看项目 README.md

---

**下一步**：安装完成后，运行 `flutter test` 开始测试！
