# FileForge - Полный гайд по деплою

## Шаг 1: Создание репозитория на GitHub

### 1.1 Создай новый репозиторий
1. Открой https://github.com/new
2. Название: `fileforge` (или любое другое)
3. Описание: `Universal File Converter`
4. Выбери Public или Private
5. НЕ добавляй README, .gitignore (они уже есть)
6. Нажми Create repository

### 1.2 Подключи и запуш
```bash
git remote add origin https://github.com/YOUR_USERNAME/fileforge.git
git branch -M main
git push -u origin main
```

## Шаг 2: Деплой на Render.com

### 2.1 Регистрация
1. Открой https://render.com
2. Войди через GitHub

### 2.2 Создание Web Service
1. New + -> Web Service
2. Build and deploy from Git repository
3. Подключи GitHub и выбери репозиторий fileforge

### 2.3 Настройка
- Name: fileforge-api
- Region: Frankfurt
- Branch: main
- Root Directory: backend/api
- Runtime: Docker
- Instance Type: Free

### 2.4 Environment Variables
- NODE_ENV = production
- PORT = 10000

### 2.5 Запуск
Нажми Create Web Service и подожди 5-10 минут.
URL будет: https://fileforge-api.onrender.com

## Шаг 3: Настройка Flutter

### 3.1 Обнови URL
В mobile-app/lib/services/api_service.dart:
```dart
static const String productionUrl = 'https://fileforge-api.onrender.com';
static const bool isProduction = true;
```

### 3.2 Сборка APK
```bash
cd mobile-app
flutter build apk --release
```

APK: mobile-app/build/app/outputs/flutter-apk/app-release.apk
