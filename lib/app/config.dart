class AppConfig {
  const AppConfig._();
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://api.alaa-dev.kdns.fr:20314');
  static const appName = 'DEX Host';
  static const maxUploadBytes = 25 * 1024 * 1024;
}
