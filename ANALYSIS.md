# 生活助理 - 项目分析报告

## 1. 项目概述

**生活助理** 是一款智能待办事项提醒应用，旨在帮助用户高效管理时间和任务。

### 目标用户
- 需要管理日常事务的上班族
- 学生群体
- 任何需要时间管理帮助的用户

### 核心价值
- 智能解析：自然语言输入自动生成待办事项
- 多维度视图：从日、周、月不同角度规划时间
- 本地存储：数据安全，隐私保护

## 2. 功能架构

### 2.1 功能模块

| 模块 | 功能 | 状态 |
|------|------|------|
| 用户认证 | 登录/注册 | ✅ 已实现 |
| 智能输入 | 自然语言解析 | ✅ 已实现 |
| 规划视图 | 今日/周/月规划 | ✅ 已实现 |
| 事项管理 | 增删改查 | ✅ 已实现 |
| 提醒功能 | 多种提醒方式 | ✅ 已实现 |
| 搜索功能 | 全文搜索 | ✅ 已实现 |
| 设置中心 | 个人设置 | ✅ 已实现 |

### 2.2 技术架构

```
┌─────────────────────────────────────┐
│           UI Layer                  │
│  (Flutter Widgets + Material 3)    │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│       State Management              │
│         (Provider)                  │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│        Business Logic               │
│   (Services + Models)               │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│         Data Layer                  │
│   (SQLite + Local Notifications)    │
└─────────────────────────────────────┘
```

## 3. 数据模型设计

### 3.1 TodoItem（待办事项）

```dart
class TodoItem {
  String id;                    // 唯一标识
  String title;                 // 标题
  String? description;          // 描述
  DateTime? reminderTime;       // 提醒时间
  DateTime? completedAt;        // 完成时间
  bool isCompleted;             // 是否完成
  bool reminderEnabled;         // 是否启用提醒
  ReminderMethod reminderMethod;// 提醒方式
  String? reminderContent;      // 提醒内容
  DateTime createdAt;           // 创建时间
  DateTime? updatedAt;          // 更新时间
  TodoPriority priority;        // 优先级
}
```

### 3.2 User（用户）

```dart
class User {
  String username;              // 用户名
  String password;              // 密码
  DateTime createdAt;           // 创建时间
}
```

## 4. 核心功能实现

### 4.1 智能解析（混合方案）

**本地NLP解析器**：
- 正则表达式匹配时间模式
- 支持相对时间（今天、明天、下周）
- 自动推断优先级
- 生成提醒内容

**AI API解析器**（可选）：
- 调用Claude API
- 更准确的上下文理解
- 处理复杂场景

**决策逻辑**：
```
输入 → 本地解析 → 结果完整？
                    ↓ 是          ↓ 否
                返回结果    调用AI API
                              ↓
                         返回结果
```

### 4.2 数据存储

**SQLite表结构**：

```sql
-- 用户表
CREATE TABLE users (
  username TEXT PRIMARY KEY,
  password TEXT NOT NULL,
  createdAt TEXT NOT NULL
);

-- 待办事项表
CREATE TABLE todos (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  reminderTime TEXT,
  completedAt TEXT,
  isCompleted INTEGER DEFAULT 0,
  reminderEnabled INTEGER DEFAULT 1,
  reminderMethod INTEGER DEFAULT 0,
  reminderContent TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT,
  priority INTEGER DEFAULT 1,
  FOREIGN KEY (username) REFERENCES users (username)
);
```

### 4.3 通知系统

**通知流程**：
1. 用户创建事项并设置提醒
2. 调用 `NotificationService.scheduleTodoReminder()`
3. 系统在指定时间触发通知
4. 用户点击通知打开应用

**支持的提醒方式**：
- 通知（Notification）
- 声音（Sound）
- 震动（Vibration）
- 声音+震动（Sound + Vibration）

## 5. 用户界面设计

### 5.1 导航结构

```
底部导航栏（5个标签）
├── 首页 - 功能入口
├── 搜索 - 搜索事项
├── 输入 - 智能输入
├── 我的 - 事项列表
└── 设置 - 应用设置
```

### 5.2 设计规范

**颜色方案**：
- 主色：#007AFF（iOS蓝色）
- 成功：#4CAF50（绿色）
- 警告：#FF9800（橙色）
- 危险：#F44336（红色）

**字体规范**：
- 标题：headlineMedium
- 正文：bodyMedium
- 辅助：bodySmall

## 6. 测试策略

### 6.1 单元测试
- 数据模型测试
- 服务层测试
- 工具函数测试

### 6.2 集成测试
- 用户流程测试
- 数据持久化测试
- 通知功能测试

### 6.3 UI测试
- 页面导航测试
- 表单验证测试
- 交互测试

## 7. 性能优化

### 7.1 已实现的优化
- SQLite索引优化
- 列表懒加载
- 状态管理优化

### 7.2 可优化的方向
- 图片缓存
- 数据预加载
- 动画优化

## 8. 安全考虑

### 8.1 数据安全
- 密码加密存储（需实现）
- 本地数据访问控制
- 通知内容脱敏

### 8.2 隐私保护
- 数据本地存储
- 不收集用户信息
- 无网络请求（可选AI功能除外）

## 9. 未来规划

### 9.1 短期目标
- [ ] 完善单元测试
- [ ] 优化UI/UX
- [ ] 添加深色模式完美支持
- [ ] 实现密码加密

### 9.2 长期目标
- [ ] 云端同步功能
- [ ] 多设备支持
- [ ] 事项分类/标签
- [ ] 统计分析功能
- [ ] Widget小组件
- [ ] Siri集成

## 10. 部署说明

### 10.1 iOS部署
1. 配置开发者账号
2. 设置Bundle Identifier
3. 配置签名证书
4. 提交App Store审核

### 10.2 注意事项
- 确保通知权限配置正确
- 检查iOS版本兼容性
- 遵循Apple设计规范

## 11. 维护和更新

### 11.1 版本管理
- 遵循语义化版本规范
- 记录版本变更日志
- 保持向后兼容

### 11.2 问题反馈
- 收集用户反馈
- 优先处理关键问题
- 定期发布更新

---

**文档版本**: 1.0.0
**最后更新**: 2026-04-13
**维护者**: 开发团队
