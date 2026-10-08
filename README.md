# DEX Host

**Powerful Hosting. Simplified.** — تطبيق Android Premium لإدارة السيرفرات والملفات والـPython Bots من الهاتف عبر FastAPI Backend الحقيقي.

## Features

- Login/Register مع JWT محفوظ في `flutter_secure_storage`.
- Auto-login مع `GET /me` للتحقق من الجلسة وتحديد الدور.
- User Dashboard: server status/resources، Quick Actions، Announcements.
- Server controls: Start، Stop، Restart، Kill، Command بحد 500 حرف، Reinstall بتأكيد.
- File Manager: browsing، breadcrumbs، upload حتى 25MB، create folder، edit، rename، copy، delete، compress، decompress، download.
- Bot Manager: upload Python، منع `app.py`، status، start/stop، restart، logs، clear logs، environment variables.
- Live Bot Logs Engine مستقل: WebSocket أولاً على `/ws/logs` مع تحويل HTTP→WS وHTTPS→WSS، parser مرن للرسائل النصية وJSON، reconnect backoff، ثم HTTP polling fallback على `GET /bots/{fname}/logs?lines=2000` عند فشل WebSocket.
- شاشة Logs Terminal بـListView.builder، filters، search/highlight، Pause/Resume، Clear View، Clear Server Logs بتأكيد، Auto-scroll وNew Logs indicator وحالة LIVE/RECONNECTING/OFFLINE.
- Backups: create، restore، download، delete.
- Profile، Change Password، Logout All، Startup Variables، Announcements.
- Admin Dashboard: stats، users/search، ban/unban/delete، force logout، pool، audit، settings.
- Arabic/English architecture مع RTL للعربية.
- Connection Manager وOffline Banner وإعادة المحاولة التلقائية.
- GitHub Actions Workflow يتأكد من `flutter analyze` و`flutter test` قبل بناء APK/AAB.

## Architecture

```text
Presentation
  ↓
Riverpod / Controllers
  ↓
Repository
  ↓
ApiClient / Dio
  ↓
FastAPI Backend
```

المسارات موجودة داخل `lib/app` و`lib/core` و`lib/features`. لا توجد API calls داخل Widgets إلا عبر Repository provider.

## API Configuration

الرابط الافتراضي:

```text
http://api.alaa-dev.kdns.fr:20314
```

يتم تغييره بدون تعديل الكود:

```bash
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

وWebSocket يتحول تلقائياً إلى `ws://` أو `wss://` حسب Base URL.

## Android permissions

يضيف Krinry تلقائيًا `INTERNET` و`ACCESS_NETWORK_STATE`، مع السماح باتصال HTTP التطويري لأن Base URL الحالي يستخدم HTTP. لا يحتاج File Picker إلى صلاحية تخزين عامة؛ فهو يستخدم Android System Picker.

## Security

لا توجد داخل التطبيق أي Pterodactyl/KataBump API keys أو JWT secret أو Fernet key أو Admin password. التطبيق يعرف فقط Base URL وJWT session، ولا يطبع الأسرار أو JWT في logs.

## Krinry / GitHub Actions

لا يوجد Android folder يدوي داخل المستودع. الـWorkflow ينفذ:

```bash
flutter pub get
flutter analyze
flutter test
flutter create --org com.alaa --platforms android .
flutter build apk --release
```

Package name الناتج:

```text
com.alaa.dex_host
```

للتشغيل من Termux:

```bash
cd dex_host
git add .
git commit -m "DEX Host production app"
git push
```

ثم شغّل `krinry Build` من GitHub Actions.

## Testing

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

الـWorkflow يوقف البناء مبكراً إذا فشل analyze أو test.

## OpenAPI Rule

تم بناء Repository على المسارات الموجودة في OpenAPI المرفق فقط. لا يتم تنفيذ `pip` داخل Flutter، ولا توجد Mock data في التطبيق النهائي. عند فشل WebSocket يستخدم Bot Logs HTTP كـfallback.
