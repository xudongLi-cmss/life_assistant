@echo off
echo ========================================
echo Flutter SDK 一键配置脚本
echo ========================================
echo.

REM 检查Flutter目录
if not exist "D:\flutter\bin\flutter.bat" (
    echo ❌ Flutter SDK未找到
    echo 请确认已解压到 D:\flutter
    pause
    exit /b 1
)

echo ✅ Flutter SDK已找到
echo.

REM 设置临时环境变量
set "PATH=D:\flutter\bin;%PATH%"

echo [1/4] 配置Git仓库...
cd /d D:\flutter
if not exist ".git" (
    git init
    git config user.email "flutter@local"
    git config user.name "Flutter User"
    git remote add origin https://github.com/flutter/flutter.git
    echo ✅ Git仓库已初始化
) else (
    echo ✓ Git仓库已存在
)
echo.

echo [2/4] 检查Flutter版本...
flutter --version
if errorlevel 1 (
    echo ❌ Flutter运行失败
    pause
    exit /b 1
)
echo.

echo [3/4] 配置用户环境变量...
echo 正在添加Flutter到系统PATH...
setx PATH "D:\flutter\bin;%PATH%" >nul 2>&1
if errorlevel 1 (
    echo ⚠️  需要管理员权限才能设置系统环境变量
    echo 请手动添加 D:\flutter\bin 到系统PATH
) else (
    echo ✅ 环境变量已设置
)
echo.

echo [4/4] 进入项目目录...
cd /d "%~dp0"
echo ✅ 当前目录: %CD%
echo.

echo ========================================
echo ✅ Flutter配置完成！
echo ========================================
echo.
echo 下一步操作：
echo 1. 关闭并重新打开VSCode
echo 2. 运行 flutter pub get 安装依赖
echo 3. 运行 flutter test 执行测试
echo.

pause
