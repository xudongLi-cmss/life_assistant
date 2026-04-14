import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/todo/todo_detail_screen.dart';
import 'screens/todo/todo_edit_screen.dart';
import 'services/storage_service_stub.dart';
import 'services/notification_service.dart';
import 'models/user.dart';
import 'models/todo_item.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化通知服务
  await NotificationService.initialize();

  // 初始化存储服务
  await StorageService.initialize();

  // 检查登录状态
  final User? currentUser = await StorageService.getCurrentUser();

  runApp(MyApp(currentUser: currentUser));
}

class MyApp extends StatelessWidget {
  final User? currentUser;

  const MyApp({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(currentUser),
      child: MaterialApp(
        title: '生活助理',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: currentUser == null ? const LoginScreen() : const HomeScreen(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          // 路由生成器
          switch (settings.name) {
            case '/todo/detail':
              final todo = settings.arguments as TodoItem?;
              if (todo == null) return null;
              return MaterialPageRoute(
                builder: (_) => TodoDetailScreen(todo: todo),
              );
            case '/todo/edit':
              final todo = settings.arguments as TodoItem?;
              if (todo == null) return null;
              return MaterialPageRoute(
                builder: (_) => TodoEditScreen(todo: todo),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

// 用户状态管理
class UserProvider with ChangeNotifier {
  User? _currentUser;

  UserProvider(this._currentUser);

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<void> login(String username, String password) async {
    final user = await StorageService.login(username, password);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> register(String username, String password) async {
    final user = await StorageService.register(username, password);
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> checkUserExists(String username) async {
    return await StorageService.userExists(username);
  }
}
