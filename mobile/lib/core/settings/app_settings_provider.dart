import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  final SharedPreferencesAsync _localStore = SharedPreferencesAsync();

  static const String _volumeKey = 'conviva_device_volume';
  static const String _settingsPrefix = 'conviva_settings_';

  String? _currentUserId;
  bool _initialized = false;
  int _initializationGeneration = 0;

  Future<void> _saveQueue = Future<void>.value();

  @override
  AppSettings build() => const AppSettings();

  String _localKey(String? userId) {
    return '$_settingsPrefix${userId ?? 'guest'}';
  }

  DocumentReference<Map<String, dynamic>> _cloudDocument(
    String userId,
  ) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('appSettings');
  }

  /// Carrega primeiro o cache local e, quando houver uma conta,
  /// tenta recuperar as preferências sincronizadas no Firestore.
  ///
  /// Sem conexão ou em caso de erro de sincronização, mantém
  /// os valores locais ou os valores padrão.
  Future<void> initialize({String? userId}) async {
    final normalizedUserId = userId?.trim().isNotEmpty == true
        ? userId!.trim()
        : null;

    if (_initialized && _currentUserId == normalizedUserId) {
      return;
    }

    final generation = ++_initializationGeneration;

    _initialized = false;
    _currentUserId = normalizedUserId;

    String? localJson;
    double? savedVolume;
    AppSettings? localSettings;

    try {
      localJson = await _localStore.getString(
        _localKey(normalizedUserId),
      );

      savedVolume = await _localStore.getDouble(_volumeKey);

      if (localJson != null) {
        final decoded = jsonDecode(localJson);

        if (decoded is Map) {
          localSettings = AppSettings.fromMap(
            Map<String, dynamic>.from(decoded),
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Erro ao carregar configurações locais: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (generation != _initializationGeneration) return;

    state = (localSettings ?? const AppSettings()).copyWith(
      volume: savedVolume ??
          localSettings?.volume ??
          const AppSettings().volume,
    );

    if (normalizedUserId != null) {
      try {
        final document = await _cloudDocument(normalizedUserId).get();

        if (generation != _initializationGeneration) return;

        final cloudData = document.data();

        if (cloudData != null) {
          // O volume é exclusivo deste dispositivo.
          state = AppSettings.fromMap(cloudData).copyWith(
            volume: state.volume,
          );
        } else if (localSettings != null) {
          // Se só existe a cópia local desta conta, tenta
          // enviá-la para a nuvem como ponto de partida.
          await _cloudDocument(normalizedUserId).set(
            state.toCloudMap(),
            SetOptions(merge: true),
          );
        }
      } catch (error, stackTrace) {
        debugPrint(
          'Não foi possível sincronizar as configurações: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (generation != _initializationGeneration) return;

    _initialized = true;

    try {
      await _writeLocal(state, normalizedUserId);
    } catch (error, stackTrace) {
      debugPrint('Erro ao guardar o cache de configurações: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _writeLocal(
    AppSettings settings,
    String? userId,
  ) async {
    // Guarda em cache somente as preferências sincronizáveis.
    await _localStore.setString(
      _localKey(userId),
      jsonEncode(settings.toCloudMap()),
    );

    // O volume é uma preferência do dispositivo, não da conta.
    await _localStore.setDouble(_volumeKey, settings.volume);
  }

  void _update(
    AppSettings newSettings, {
    bool syncCloud = true,
  }) {
    state = newSettings;
    _schedulePersistence(syncCloud: syncCloud);
  }

  void _schedulePersistence({required bool syncCloud}) {
    if (!_initialized) return;

    final settingsSnapshot = state;
    final userId = _currentUserId;

    // Serializa as gravações para evitar que uma alteração antiga
    // termine depois de uma alteração mais recente.
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _writeLocal(settingsSnapshot, userId);
      } catch (error, stackTrace) {
        debugPrint('Erro ao salvar preferências locais: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      if (!syncCloud || userId == null) return;

      try {
        await _cloudDocument(userId).set(
          settingsSnapshot.toCloudMap(),
          SetOptions(merge: true),
        );
      } catch (error, stackTrace) {
        debugPrint('Erro ao salvar preferências na nuvem: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
  }

  void setFontScale(double value) {
    _update(
      state.copyWith(
        fontScale: value.clamp(0.85, 1.40).toDouble(),
      ),
    );
  }

  void setTitleFontWeight(FontWeight value) {
    _update(state.copyWith(titleFontWeight: value));
  }

  void setBodyFontWeight(FontWeight value) {
    _update(state.copyWith(bodyFontWeight: value));
  }

  void setIconScale(double value) {
    _update(
      state.copyWith(
        iconScale: value.clamp(0.85, 1.40).toDouble(),
      ),
    );
  }

  void setButtonScale(double value) {
    _update(
      state.copyWith(
        buttonScale: value.clamp(0.90, 1.30).toDouble(),
      ),
    );
  }

  void setSpacingScale(double value) {
    _update(
      state.copyWith(
        spacingScale: value.clamp(0.90, 1.20).toDouble(),
      ),
    );
  }

  void setVolume(double value) {
    _update(
      state.copyWith(
        volume: value.clamp(0, 1).toDouble(),
      ),
      syncCloud: false,
    );
  }

  void setMessageNotifications(bool value) {
    _update(state.copyWith(messageNotifications: value));
  }

  void setReminderNotifications(bool value) {
    _update(state.copyWith(reminderNotifications: value));
  }

  void setColorIntensity(double value) {
    _update(
      state.copyWith(
        colorIntensity: value.clamp(0.5, 1).toDouble(),
      ),
    );
  }

  void setPalette({
    required Color primaryColor,
    required Color gradientTop,
    required Color gradientBottom,
  }) {
    _update(
      state.copyWith(
        primaryColor: primaryColor,
        gradientTop: gradientTop,
        gradientBottom: gradientBottom,
      ),
    );
  }

  void reset() {
    _update(const AppSettings());
  }
}
