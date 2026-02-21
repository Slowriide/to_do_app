import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/config/local_storage/local_storage.dart';
import 'package:to_do_app/presentation/cubits/theme/theme_cubit.dart';

void main() {
  Future<ThemeCubit> createCubitWithPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    await LocalStorage.configurePrefs();
    return ThemeCubit();
  }

  test('initializes with defaults when preferences are empty', () async {
    final cubit = await createCubitWithPrefs({});

    expect(cubit.state.isDarkmode, isFalse);
    expect(cubit.state.presetId, 'oceanBlue');
    expect(cubit.state.activeColorSource, ThemeColorSource.preset);
    expect(cubit.state.customColorHex, isNull);
    await cubit.close();
  });

  test('setLightMode and setDarkMode persist and emit', () async {
    final cubit = await createCubitWithPrefs({});

    cubit.setDarkMode();
    expect(cubit.state.isDarkmode, isTrue);
    expect(LocalStorage.isDarkMode, isTrue);

    cubit.setLightMode();
    expect(cubit.state.isDarkmode, isFalse);
    expect(LocalStorage.isDarkMode, isFalse);
    await cubit.close();
  });

  test('selectPreset updates state and local storage', () async {
    final cubit = await createCubitWithPrefs({});

    cubit.selectPreset('forestGreen');

    expect(cubit.state.presetId, 'forestGreen');
    expect(cubit.state.activeColorSource, ThemeColorSource.preset);
    expect(LocalStorage.themePresetId, 'forestGreen');
    expect(LocalStorage.themeColorSource, 'preset');
    await cubit.close();
  });

  test('setCustomColorHex with valid value persists custom source', () async {
    final cubit = await createCubitWithPrefs({});

    final success = cubit.setCustomColorHex('1a73e8');

    expect(success, isTrue);
    expect(cubit.state.customColorHex, '#1A73E8');
    expect(cubit.state.activeColorSource, ThemeColorSource.custom);
    expect(LocalStorage.customThemeHex, '#1A73E8');
    expect(LocalStorage.themeColorSource, 'custom');
    await cubit.close();
  });

  test('setCustomColorHex with invalid value does not mutate state', () async {
    final cubit = await createCubitWithPrefs({
      'customThemeHex': '#ABCDEF',
      'themeColorSource': 'custom',
    });
    final before = cubit.state;

    final success = cubit.setCustomColorHex('ZZZZZZ');

    expect(success, isFalse);
    expect(cubit.state, before);
    expect(LocalStorage.customThemeHex, '#ABCDEF');
    expect(LocalStorage.themeColorSource, 'custom');
    await cubit.close();
  });
}
