# VSCode Flutter 快速配置指南

## 📋 基于CSDN教程的简化步骤

### 当前状态
- ✅ Flutter SDK: D:\flutter (已下载)
- ✅ 项目代码: d:\lxd\lixudong\myapp (已完成)
- ✅ Git: 已安装
- ⏸ VSCode配置: 待完成

## 🚀 三步配置法

### 步骤1: 在VSCode中配置Flutter路径

1. **打开命令面板**
   - 按 `Ctrl + Shift + P`
   - 输入 `flutter`
   - 选择 `Flutter: Locate SDK`

2. **选择Flutter目录**
   - 导航到 `D:\flutter`
   - 点击"选择Flutter SDK"

### 步骤2: 配置国内镜像（解决网络问题）

在VSCode终端（PowerShell）中运行：

```powershell
# 设置Flutter和Dart的国内镜像
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"

# 验证配置
echo $env:PUB_HOSTED_URL
echo $env:FLUTTER_STORAGE_BASE_URL
```

### 步骤3: 安装依赖并运行

```powershell
# 进入项目目录
cd d:\lxd\lixudong\myapp

# 安装依赖
flutter pub get

# 运行测试
flutter test

# 启动应用（Chrome浏览器）
flutter run -d chrome
```

## 🔧 如果遇到问题

### 问题1: "Flutter SDK not found"
**解决方案**:
1. 在VSCode中按 `Ctrl + ,` 打开设置
2. 搜索 `flutter sdk path`
3. 设置为 `D:\flutter`

### 问题2: 依赖下载慢或失败
**解决方案**:
```powershell
# 使用国内镜像
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

### 问题3: flutter doctor 显示错误
**解决方案**:
这是正常的，只需要Web开发即可。忽略Android/Windows相关错误。

## ✅ 验证配置成功

运行以下命令应该看到版本信息：
```bash
flutter --version
```

预期输出：
```
Flutter 3.24.5 • channel stable
Dart 3.5.3
```

## 🎯 快速启动脚本

创建文件 `start.bat`：
```batch
@echo off
set "PATH=D:\flutter\bin;%PATH%"
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
set "FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn"

cd /d d:\lxd\lixudong\myapp
flutter pub get
flutter run -d chrome
```

---

**参考**: [CSDN教程](https://blog.csdn.net/jo11y/article/details/147657810)
