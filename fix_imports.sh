#!/bin/bash

files=(
  "lib/screens/search/search_screen.dart"
  "lib/screens/home/month_plan_screen.dart"
  "lib/screens/home/week_plan_screen.dart"
  "lib/screens/home/today_plan_screen.dart"
  "lib/screens/input/input_screen.dart"
  "lib/screens/settings/settings_screen.dart"
  "lib/screens/todo/todo_add_screen.dart"
  "lib/screens/todo/todo_edit_screen.dart"
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    # 修复导入
    sed -i "s|'services/storage_service.dart'|'services/storage_service_stub.dart'|g" "$file"
    echo "Fixed: $file"
  fi
done
