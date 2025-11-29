# FileForge - Инструкция по деплою

## Деплой на Render.com (бесплатно)

### 1. Подготовка
1. Создай аккаунт на [render.com](https://render.com)
2. Подключи свой GitHub репозиторий

### 2. Деплой API
1. В Render Dashboard нажми "New" → "Web Service"
2. Выбери свой репозиторий
3. Настройки:
   - **Name**: `fileforge-api`
   - **Region**: Frankfurt (или ближайший)
   - **Root Directory**: `backend/api`
   - **Runtime**: Docker
   - **Plan**: Free

4. Environment Variables:
   - `NODE_ENV` = `production`
   - `PORT` = `10000`

5. Нажми "Create Web Service"

### 3. После деплоя
После успешного деплоя ты получишь URL вида:
```
https://fileforge-api.onrender.com
```

### 4. Обновление Flutter приложения
Открой `mobile-app/lib/services/api_service.dart` и обнови:

```dart
class ApiConfig {
  // Замени на свой URL с Render
  static const String productionUrl = 'https://fileforge-api.onrender.com';
  
  // Включи production режим
  static const bool isProduction = true;
}
```

### 5. Сборка APK
```bash
cd mobile-app
flutter build apk --release
```

APK будет в: `build/app/outputs/flutter-apk/app-release.apk`

---

## Альтернативы (тоже бесплатно)

### Railway.app
1. Подключи GitHub
2. Выбери `backend/api` как root
3. Railway автоматически определит Dockerfile

### Fly.io
```bash
cd backend/api
flyctl launch
flyctl deploy
```

---

## Ограничения бесплатного плана Render

- Сервис "засыпает" после 15 минут неактивности
- Первый запрос после сна занимает ~30 секунд
- 750 часов в месяц (достаточно для одного сервиса 24/7)
- Файлы удаляются при перезапуске (in-memory storage)

## Для production
Для реального использования рекомендуется:
- Использовать платный план
- Добавить Redis для очередей
- Добавить S3/MinIO для хранения файлов
