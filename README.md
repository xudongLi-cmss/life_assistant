# 生活助理 - 智能事项提醒应用

一款基于Flutter开发的iOS智能待办事项提醒应用，支持自然语言解析、智能提醒和多维度规划查看。

## 功能特性

### 核心功能
- ✅ 用户认证：登录/注册系统
- ✅ 智能输入：AI驱动的事项自动识别和解析
- ✅ 多维度规划：今日/整周/整月规划视图
- ✅ 事项管理：添加/编辑/删除/查看详情
- ✅ 智能提醒：支持多种提醒方式（通知/声音/震动）
- ✅ 搜索功能：快速搜索待办事项
- ✅ 本地存储：SQLite数据库存储

### 智能解析示例

输入：
```
我今天下午四点要定西安到北京的高铁，在晚上20点前要发一份邮件给老板，明天早上8点开会，下周一前完成《AI行业报告分析》材料的撰写。
```

自动解析为：
1. 今天 16:00 - 定西安到北京的高铁
2. 今天 20:00 - 发邮件给老板
3. 明天 08:00 - 开会
4. 下周一 - 完成《AI行业报告分析》材料

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **状态管理**: Provider
- **本地存储**: SQLite (sqflite)
- **通知**: flutter_local_notifications
- **AI解析**: 混合方案（本地NLP + Claude API可选）

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/                      # 数据模型
│   ├── todo_item.dart          # 待办事项模型
│   └── user.dart               # 用户模型
├── screens/                     # 页面
│   ├── auth/                   # 认证相关
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/                   # 主页相关
│   │   ├── home_screen.dart
│   │   ├── today_plan_screen.dart
│   │   ├── week_plan_screen.dart
│   │   └── month_plan_screen.dart
│   ├── todo/                   # 事项管理
│   │   ├── todo_add_screen.dart
│   │   ├── todo_edit_screen.dart
│   │   └── todo_detail_screen.dart
│   ├── search/                 # 搜索
│   │   └── search_screen.dart
│   ├── input/                  # 智能输入
│   │   └── input_screen.dart
│   └── settings/               # 设置
│       └── settings_screen.dart
└── services/                    # 服务层
    ├── storage_service.dart    # 存储服务
    ├── notification_service.dart # 通知服务
    ├── ai_parser_service.dart  # AI解析服务
    └── local_nlp_parser.dart   # 本地NLP解析
```

## 安装和运行

### 前置要求
- Flutter SDK 3.x
- Dart SDK 3.x
- Xcode（iOS开发）
- Android Studio / VS Code

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd myapp
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
# iOS模拟器
flutter run -d ios

# 或指定设备
flutter devices
flutter run -d <device-id>
```

## 配置说明

### AI API配置（可选）

如果需要使用Claude API进行更准确的智能解析，请在 `lib/services/ai_parser_service.dart` 中配置：

```dart
static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY'; // 替换为实际的API密钥
```

如果不配置API密钥，应用会使用本地NLP解析器，功能仍然可用。

### 本地化配置

应用支持中文界面，如需添加其他语言支持，请配置flutter_localizations。

## 数据存储

所有数据存储在本地SQLite数据库中：
- 用户信息：用户名、密码（加密存储）
- 待办事项：标题、描述、时间、优先级、提醒设置等
- 数据位置：iOS应用沙盒目录

## 测试用例

### 登录页面测试
1. 用户名输入错误 → 提示用户名错误
2. 密码输入错误 → 提示密码错误
3. 用户名密码正确 → 进入主界面
4. 用户名密码为空 → 提示不能为空
5. 用户名不存在 → 提示用户名不存在并建议注册

### 注册页面测试
1. 用户名已存在 → 提示用户名已存在
2. 用户名密码为空 → 提示不能为空
3. 输入合法信息 → 提示注册成功
4. 输入非法用户名 → 提示输入非法

## 开发说明

### 添加新功能
1. 在 `models/` 中定义数据模型
2. 在 `services/` 中实现业务逻辑
3. 在 `screens/` 中创建UI界面
4. 更新路由配置

### 代码风格
- 遵循Flutter官方代码规范
- 使用有意义的变量和函数命名
- 添加必要的注释

## 版本信息

- 当前版本：V1.0.0
- Flutter版本：3.x
- Dart版本：3.x
- 目标平台：iOS

## 许可证

本项目仅供学习和参考使用。

## 联系方式

如有问题或建议，请通过以下方式联系：
- 提交Issue
- 发送邮件

---

**生活助理** - 让生活更高效，让时间更有价值！
