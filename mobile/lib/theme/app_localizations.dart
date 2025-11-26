import 'package:flutter/material.dart';
import 'package:mobile/theme/settings_provider.dart';
import 'package:provider/provider.dart';

class AppLocalizations {
  static String of(BuildContext context, String key, {bool listen = true}) {
    final settings = Provider.of<SettingsProvider>(context, listen: listen);
    final isBg = settings.locale.languageCode == 'bg';
    return isBg ? (bg[key] ?? key) : (en[key] ?? key);
  }

  static const en = {
    // General
    'app_name': 'LostMost',
    'cancel': 'Cancel',
    'confirm': 'Confirm',
    'save': 'Save',
    'error': 'Error',
    'success': 'Success',
    'loading': 'Loading...',

    // Navbar
    'nav_home': 'Home',
    'nav_search': 'Search',
    'nav_settings': 'Settings',

    // Home
    'home_title': 'RSSI Viewer',
    'connecting': 'Connecting...',
    'proximity_close': 'Close',
    'proximity_nearby': 'Nearby',
    'proximity_far': 'Far',

    // Search
    'search_title': 'Search',
    'search_page': 'Search Page',

    // Auth
    'login_title': 'Login',
    'login_subtitle': 'Welcome back',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm Password',
    'login_button': 'Login',
    'signup_button': 'Sign Up',
    'no_account': "Don't have an account? Sign Up",
    'have_account': 'Already have an account? Login',
    'passwords_mismatch': "Passwords don't match",
    'forgot_password': 'Forgot Password?',

    // Profile
    'profile_title': 'Profile',
    'account': 'Account',
    'appearance': 'Appearance',
    'theme': 'Theme',
    'system': 'System',
    'light': 'Light',
    'dark': 'Dark',
    'choose_look': 'Choose how the app looks to you',
    'language': 'Language',
    'app_language': 'App Language',
    'data_storage': 'Data & Storage',
    'data_saver': 'Data Saver',
    'reduce_data': 'Reduce data usage',
    'clear_cache': 'Clear Cache',
    'clear_cache_confirm': 'Are you sure you want to clear the app cache?',
    'clear': 'Clear',
    'about': 'About',
    'version': 'Version',
    'source_code': 'Source Code',
    'color_preview': 'Color Preview',
    'primary_color': 'Primary',
    'secondary_color': 'Secondary',
    'success_color': 'Success',
    'warning_color': 'Warning',
    'danger_color': 'Danger',
    'info_color': 'Info',
    'logout': 'Log out',
    'logout_confirm': 'Are you sure you want to log out?',
    'change_password': 'Change Password',
    'new_password': 'New Password',
    'password_updated': 'Password updated successfully',
    'password_update_failed': 'Failed to update password',
  };

  static const bg = {
    // General
    'app_name': 'LostMost',
    'cancel': 'Отказ',
    'confirm': 'Потвърди',
    'save': 'Запази',
    'error': 'Грешка',
    'success': 'Успех',
    'loading': 'Зареждане...',

    // Navbar
    'nav_home': 'Начало',
    'nav_search': 'Търсене',
    'nav_settings': 'Настройки',

    // Home
    'home_title': 'RSSI Преглед',
    'connecting': 'Свързване...',
    'proximity_close': 'Близо',
    'proximity_nearby': 'Наблизо',
    'proximity_far': 'Далеч',

    // Search
    'search_title': 'Търсене',
    'search_page': 'Страница за търсене',

    // Auth
    'login_title': 'Вход',
    'login_subtitle': 'Добре дошли отново',
    'email': 'Имейл',
    'password': 'Парола',
    'confirm_password': 'Потвърди парола',
    'login_button': 'Вход',
    'signup_button': 'Регистрация',
    'no_account': 'Нямате акаунт? Регистрирайте се',
    'have_account': 'Вече имате акаунт? Влезте',
    'passwords_mismatch': 'Паролите не съвпадат',
    'forgot_password': 'Забравена парола?',

    // Profile
    'profile_title': 'Профил',
    'account': 'Акаунт',
    'appearance': 'Външен вид',
    'theme': 'Тема',
    'system': 'Системна',
    'light': 'Светла',
    'dark': 'Тъмна',
    'choose_look': 'Изберете как да изглежда приложението',
    'language': 'Език',
    'app_language': 'Език на приложението',
    'data_storage': 'Данни и памет',
    'data_saver': 'Икономия на данни',
    'reduce_data': 'Намаляване на използването на данни',
    'clear_cache': 'Изчистване на кеша',
    'clear_cache_confirm': 'Сигурни ли сте, че искате да изчистите кеша?',
    'clear': 'Изчисти',
    'about': 'За приложението',
    'version': 'Версия',
    'source_code': 'Изходен код',
    'color_preview': 'Преглед на цветовете',
    'primary_color': 'Основен',
    'secondary_color': 'Вторичен',
    'success_color': 'Успешно',
    'warning_color': 'Внимание',
    'danger_color': 'Опасност',
    'info_color': 'Информация',
    'logout': 'Изход',
    'logout_confirm': 'Сигурни ли сте, че искате да излезете?',
    'change_password': 'Смяна на парола',
    'new_password': 'Нова парола',
    'password_updated': 'Паролата е обновена успешно',
    'password_update_failed': 'Грешка при обновяване на паролата',
  };
}
