import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_settings.dart';

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
      AppSettingsNotifier.new,
    );

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setFontScale(double value) {
    state = state.copyWith(
      fontScale: value.clamp(0.85, 1.40).toDouble(),
    );
  }

  void setTitleFontWeight(FontWeight value) {
    state = state.copyWith(titleFontWeight: value);
  }

  void setBodyFontWeight(FontWeight value) {
    state = state.copyWith(bodyFontWeight: value);
  }

  void setIconScale(double value) {
    state = state.copyWith(
      iconScale: value.clamp(0.85, 1.40).toDouble(),
    );
  }

  void setButtonScale(double value) {
    state = state.copyWith(
      buttonScale: value.clamp(0.90, 1.30).toDouble(),
    );
  }

  void setSpacingScale(double value) {
    state = state.copyWith(
      spacingScale: value.clamp(0.90, 1.20).toDouble(),
    );
  }

  void setVolume(double value) {
    state = state.copyWith(
      volume: value.clamp(0, 1).toDouble(),
    );
  }

  void setMessageNotifications(bool value) {
    state = state.copyWith(messageNotifications: value);
  }

  void setReminderNotifications(bool value) {
    state = state.copyWith(reminderNotifications: value);
  }

  void setColorIntensity(double value) {
    state = state.copyWith(
      colorIntensity: value.clamp(.5, 1).toDouble(),
    );
  }

  void setPalette({
    required Color primaryColor,
    required Color gradientTop,
    required Color gradientBottom,
  }) {
    state = state.copyWith(
      primaryColor: primaryColor,
      gradientTop: gradientTop,
      gradientBottom: gradientBottom,
    );
  }

  void reset() {
    state = const AppSettings();
  }
}
