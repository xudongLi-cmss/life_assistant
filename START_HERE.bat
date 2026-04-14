@echo off
REM ========================================
REM 生活助理 - 一键启动脚本
REM ========================================

echo.
echo ========================================
echo 生活助理 - Flutter 项目启动
echo ========================================
echo.

REM 设置Flutter路径
set "FLUTTER_PATH=D:\flutter"
set "PATH=%FLUTTER_PATH%\bin;%PATH%"

echo [1/5] 检查Flutter安装...
if not exist "%FLUTTER_PATH%\bin\flutter.bat" (
    echo ❌ Flutter未找到在 %FLUTTER_PATH%
    pause
    exit /b 1
)
echo ✅ Flutter已找到
echo.

echo [2/5] 进入项目目录...
cd /d "%~dp0"
echo ✅ 当前目录: %CD%
echo.

echo [3/5] 检查Flutter版本...
flutter --version
if errorlevel 1 (
    echo ⚠️  Flutter运行可能需要初始化
    echo 首次运行可能需要几分钟...
)
echo.

echo [4/5] 安装项目依赖...
echo 正在运行: flutter pub get
echo.
flutter pub get
if errorlevel 1 (
    echo ❌ 依赖安装失败
    pause
    exit /b 1
)
echo ✅ 依赖安装完成
echo.

echo [5/5] 运行应用...
echo.
echo 请选择运行方式:
echo 1. Chrome 浏览器（推荐）
echo 2. Windows 桌面
echo 3. 仅运行测试
echo 4. 退出
echo.
set /p choice="请选择 (1-4): "

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
    echo 🧪 运行测试...
    flutter test
) else if "%choice%"=="4" (
    echo.
    echo 退出...
    exit /b 0
) else (
    echo ❌ 无效选择
)

pause
