@echo off
REM Flutter 应用运行脚本
REM 使用方法：双击此文件或在命令行中运行

echo ========================================
echo 生活助理 - Flutter 运行脚本
echo ========================================
echo.

REM 检查Flutter是否安装
echo [1/5] 检查Flutter安装...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter未安装或未添加到PATH
    echo 请先安装Flutter SDK
    pause
    exit /b 1
)
echo ✅ Flutter已安装
echo.

REM 进入项目目录
echo [2/5] 进入项目目录...
cd /d "%~dp0"
echo ✅ 当前目录: %CD%
echo.

REM 安装依赖
echo [3/5] 安装项目依赖...
flutter pub get
if errorlevel 1 (
    echo ❌ 依赖安装失败
    pause
    exit /b 1
)
echo ✅ 依赖安装完成
echo.

REM 列出可用设备
echo [4/5] 可用设备列表：
echo.
flutter devices -d
echo.

REM 询问运行方式
echo [5/5] 选择运行方式：
echo 1. Chrome 浏览器（推荐，无需模拟器）
echo 2. Windows 桌面（需要Visual Studio）
echo 3. 显示可用设备列表
echo.
set /p choice="请选择 (1-3): "

if "%choice%"=="1" (
    echo.
    echo 🚀 启动应用（Chrome）...
    flutter run -d chrome
) else if "%choice%"=="2" (
    echo.
    echo 🚀 启动应用（Windows Desktop）...
    flutter run -d windows
) else if "%choice%"=="3" (
    echo.
    flutter devices
    echo.
    set /p device="请输入设备ID: "
    flutter run -d %device%
) else (
    echo ❌ 无效选择
    pause
    exit /b 1
)

pause
