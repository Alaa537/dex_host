import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;
  static AppStrings of(BuildContext context) => AppStrings(Localizations.localeOf(context));
  bool get ar => locale.languageCode == 'ar';
  String get appName => 'DEX Host';
  String get login => ar ? 'تسجيل الدخول' : 'Login';
  String get register => ar ? 'إنشاء حساب' : 'Create account';
  String get username => ar ? 'اسم المستخدم' : 'Username';
  String get password => ar ? 'كلمة المرور' : 'Password';
  String get dashboard => ar ? 'الرئيسية' : 'Home';
  String get server => ar ? 'السيرفر' : 'Server';
  String get files => ar ? 'الملفات' : 'Files';
  String get bots => ar ? 'البوتات' : 'Bots';
  String get more => ar ? 'المزيد' : 'More';
  String get retry => ar ? 'إعادة المحاولة' : 'Retry';
  String get logout => ar ? 'تسجيل الخروج' : 'Logout';
  String get online => ar ? 'متصل' : 'Online';
  String get offline => ar ? 'غير متصل' : 'Offline';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppLocalizationsDelegate();
  @override bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);
  @override Future<AppStrings> load(Locale locale) async => AppStrings(locale);
  @override bool shouldReload(AppLocalizationsDelegate old) => false;
}
