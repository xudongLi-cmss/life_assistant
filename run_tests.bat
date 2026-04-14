@echo off
REM Flutter 测试运行脚本
REM 使用方法：双击此文件或在命令行中运行

echo ========================================
echo 生活助理 - Flutter 测试脚本
echo ========================================
echo.

REM 检查Flutter是否安装
echo [1/4] 检查Flutter安装...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter未安装或未添加到PATH
    echo 请先安装Flutter SDK: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)
echo ✅ Flutter已安装
echo.

REM 进入项目目录
echo [2/4] 进入项目目录...
cd /d "%~dp0"
if errorlevel 1 (
    echo ❌ 无法进入项目目录
    pause
    exit /b 1
)
echo ✅ 当前目录: %CD%
echo.

REM 安装依赖
echo [3/4] 安装项目依赖...
flutter pub get
if errorlevel 1 (
    echo ❌ 依赖安装失败
    echo 提示: 如果是网络问题，可以配置国内镜像
    pause
    exit /b 1
)
echo ✅ 依赖安装完成
echo.

REM 运行测试
echo [4/4] 运行测试...
echo.
flutter test

if errorlevel 1 (
    echo.
    echo ❌ 测试失败
    echo 请检查代码并修复错误
) else (
    echo.
    echo ========================================
    echo ✅ 所有测试通过！
    echo ========================================
)

echo.
echo 按任意键退出...
pause >nul
