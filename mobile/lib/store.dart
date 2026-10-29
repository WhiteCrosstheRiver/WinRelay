import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

/// App-wide persisted state. A ChangeNotifier so screens update when it changes.
class Store extends ChangeNotifier {
  Store._();
  static final Store I = Store._();

  late SharedPreferences _prefs;
  late String deviceId;
  AppSettings settings = AppSettings();
  List<PcEntry> pcs = [];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    deviceId = _prefs.getString('device_id') ?? const Uuid().v4();
    await _prefs.setString('device_id', deviceId);

    final s = _prefs.getString('settings');
    if (s != null) settings = AppSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);

    final p = _prefs.getString('pcs');
    if (p != null) {
      pcs = (jsonDecode(p) as List).map((e) => PcEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> saveSettings() async {
    await _prefs.setString('settings', jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> savePc(PcEntry pc) async {
    final i = pcs.indexWhere((x) => x.id == pc.id);
    if (i >= 0) {
      pcs[i] = pc;
    } else {
      pcs.add(pc);
    }
    await _persistPcs();
  }

  Future<void> removePc(PcEntry pc) async {
    pcs.removeWhere((x) => x.id == pc.id);
    await _persistPcs();
  }

  Future<void> _persistPcs() async {
    await _prefs.setString('pcs', jsonEncode(pcs.map((e) => e.toJson()).toList()));
    notifyListeners();
  }
}
