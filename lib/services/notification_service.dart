import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'gemini_scanner_service.dart';

class AppNotification {
  final String id;
  final String colorType; // 'violet' (AI), 'mint', 'blue', 'peach'
  final String title;
  final String sub;
  final String body;
  final String time;
  final String type; // 'ai', 'reminder', 'order', 'system'
  bool isGlow;
  bool isTaken;
  bool isProcessing;
  final Map<String, dynamic>? scanData;
  final String? imagePath;
  final int timestamp;

  AppNotification({
    required this.id,
    required this.colorType,
    required this.title,
    required this.sub,
    required this.body,
    required this.time,
    this.type = 'ai',
    this.isGlow = true,
    this.isTaken = false,
    this.isProcessing = false,
    this.scanData,
    this.imagePath,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      colorType: json['colorType']?.toString() ?? 'violet',
      title: json['title']?.toString() ?? 'Bildirishnoma',
      sub: json['sub']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      time: json['time']?.toString() ?? 'Hozirgina',
      type: json['type']?.toString() ?? 'ai',
      isGlow: json['isGlow'] is bool ? json['isGlow'] as bool : true,
      isTaken: json['isTaken'] is bool ? json['isTaken'] as bool : false,
      isProcessing: json['isProcessing'] is bool ? json['isProcessing'] as bool : false,
      scanData: json['scanData'] is Map ? Map<String, dynamic>.from(json['scanData'] as Map) : null,
      imagePath: json['imagePath']?.toString(),
      timestamp: (json['timestamp'] is num) ? (json['timestamp'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'colorType': colorType,
    'title': title,
    'sub': sub,
    'body': body,
    'time': time,
    'type': type,
    'isGlow': isGlow,
    'isTaken': isTaken,
    'isProcessing': isProcessing,
    'scanData': scanData,
    'imagePath': imagePath,
    'timestamp': timestamp,
  };
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _streamController =
      StreamController<List<AppNotification>>.broadcast();

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  Stream<List<AppNotification>> get stream => _streamController.stream;
  List<AppNotification> get items => List.unmodifiable(_notifications);

  /// Permanent storage file in Application Documents directory (never cleared by OS)
  Future<File> _getCacheFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/kumed_notifications_permanent.json');
    } catch (_) {
      return File('${Directory.systemTemp.path}/kumed_notifications_cache.json');
    }
  }

  /// Copy scanned image to permanent internal storage so it stays permanently
  Future<String?> savePermanentImage(String tempPath) async {
    try {
      final src = File(tempPath);
      if (!await src.exists()) return null;
      final dir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${dir.path}/ai_scans');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final filename = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentFile = File('${imagesDir.path}/$filename');
      await src.copy(permanentFile.path);
      return permanentFile.path;
    } catch (e) {
      debugPrint('Error saving permanent image: $e');
      return tempPath;
    }
  }

  /// Initialize and restore stored notifications from disk
  Future<void> init() async {
    try {
      final file = await _getCacheFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content);
        _notifications.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _notifications.add(AppNotification.fromJson(item));
          }
        }
      }
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }

    // Default permanent notifications as an integral part of the app
    if (_notifications.isEmpty) {
      _notifications.addAll([
        AppNotification(
          id: 'init_welcome',
          colorType: 'mint',
          title: 'Xush kelibsiz!',
          sub: 'KUmedFarm ilovasi',
          body: 'Ilovaga muvaffaqiyatli ulandingiz. Retsept yoki dorilarni AI orqali skanerlang va dorixonalarni xaritada toping.',
          time: '09:00',
          type: 'system',
          isGlow: true,
        ),
        AppNotification(
          id: 'init_reminder',
          colorType: 'blue',
          title: 'Dori ichish eslatmasi',
          sub: 'Kunlik jadval',
          body: 'Bugungi dori vositalaringizni oʻz vaqtida ichishni unutmang. Sogʻligingiz oʻz qoʻlingizda!',
          time: '08:30',
          type: 'reminder',
          isGlow: false,
        ),
        AppNotification(
          id: 'init_ai_tip',
          colorType: 'violet',
          title: 'Dr. Shifo AI yordamchisi',
          sub: '24/7 Maslahat',
          body: 'Har qanday dori qutisi yoki shifokor retseptini skanerlab, AI bilan bevosita suhbatlashing.',
          time: 'Kecha',
          type: 'ai',
          isGlow: false,
        ),
      ]);
      await _persist();
    }

    _recalculateUnread();
    _notify();
  }

  /// Persist notifications to local disk
  Future<void> _persist() async {
    try {
      final file = await _getCacheFile();
      final data = _notifications.map((n) => n.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  void _recalculateUnread() {
    final unread = _notifications.where((n) => n.isGlow).length;
    unreadCountNotifier.value = unread;
    ApiService.instance.unreadNotificationsCount.value = unread;
  }

  void _notify() {
    _streamController.add(List.unmodifiable(_notifications));
  }

  /// Start pending Gemini analysis notification (shows loading/preparing widget in Notifications)
  Future<String> startPendingGeminiAnalysis({String? imagePath}) async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final id = 'gemini_${DateTime.now().millisecondsSinceEpoch}';

    String? permPath;
    if (imagePath != null && imagePath.isNotEmpty) {
      permPath = await savePermanentImage(imagePath);
    }

    final notif = AppNotification(
      id: id,
      colorType: 'violet',
      title: 'Gemini AI',
      sub: 'AI tahlili tayyorlanmoqda...',
      body: 'Retsept yoki dori qutisi tekshirilmoqda. Tahlil tayyor boʻlgach, barcha maʼlumotlar shu yerda aks etadi.',
      time: timeStr,
      type: 'ai',
      isGlow: true,
      isTaken: false,
      isProcessing: true,
      imagePath: permPath ?? imagePath,
    );

    _notifications.insert(0, notif);
    _recalculateUnread();
    _notify();
    await _persist();
    return id;
  }

  /// Update pending notification with finished Gemini scan result
  Future<void> updateGeminiNotification({
    required String id,
    required GeminiScanResult result,
  }) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    final bool isMedicine = result.isMedicine && result.medicines.isNotEmpty;

    final String title;
    final String sub;
    final String body;
    final String colorType;

    if (!isMedicine) {
      title = '${result.detectedObject} (Dori emas)';
      sub = '${result.confidenceText} · Dori topilmadi';
      body = result.summary;
      colorType = 'peach';
    } else {
      final medNames = result.medicines.map((m) => m.name).toList();
      final medTitle = medNames.isNotEmpty ? medNames.take(2).join(', ') : result.detectedObject;
      final dosageText = result.medicines.isNotEmpty ? result.medicines.first.dosage : '';

      title = 'Gemini AI: $medTitle';
      sub = '${result.confidenceText} · Tahlil tayyor';
      body = dosageText.isNotEmpty
          ? '${result.summary}\nQoʻllash: $dosageText'
          : result.summary;
      colorType = 'violet';
    }

    final updated = AppNotification(
      id: id,
      colorType: colorType,
      title: title,
      sub: sub,
      body: body,
      time: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      type: 'ai',
      isGlow: true,
      isTaken: false,
      isProcessing: false,
      imagePath: index != -1 ? _notifications[index].imagePath : null,
      scanData: {
        'isMedicine': result.isMedicine,
        'detectedObject': result.detectedObject,
        'summary': result.summary,
        'medicines': result.medicines.map((m) => m.toJson()).toList(),
        'doctorNotes': result.doctorNotes,
        'confidence': result.confidenceText,
      },
    );

    if (index != -1) {
      _notifications[index] = updated;
    } else {
      _notifications.insert(0, updated);
    }

    _recalculateUnread();
    _notify();
    await _persist();

    // Broadcast to backend web dashboard if connected
    try {
      ApiService.instance.broadcastNotification(
        title: updated.title,
        message: updated.body,
        type: 'ai',
      );
    } catch (_) {}
  }

  /// Add a Gemini AI analysis result notification directly
  Future<void> addGeminiScanNotification({
    required String summary,
    required List<String> medicineNames,
    required String confidenceText,
    String? dosageSummary,
    Map<String, dynamic>? scanData,
  }) async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    final medTitles = medicineNames.isNotEmpty
        ? medicineNames.take(2).join(', ')
        : 'Dori vositasi';

    final notif = AppNotification(
      id: 'gemini_${DateTime.now().millisecondsSinceEpoch}',
      colorType: 'violet',
      title: 'Gemini AI: $medTitles',
      sub: '$confidenceText · Tahlil tayyor',
      body: dosageSummary != null && dosageSummary.isNotEmpty
          ? '$summary\nQoʻllash: $dosageSummary'
          : summary,
      time: timeStr,
      type: 'ai',
      isGlow: true,
      isTaken: false,
      isProcessing: false,
      scanData: scanData,
    );

    _notifications.insert(0, notif);
    _recalculateUnread();
    _notify();
    await _persist();

    try {
      ApiService.instance.broadcastNotification(
        title: notif.title,
        message: notif.body,
        type: 'ai',
      );
    } catch (_) {}
  }

  /// Add generic notification
  Future<void> addNotification({
    required String title,
    required String sub,
    required String body,
    String colorType = 'mint',
    String type = 'system',
  }) async {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final notif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      colorType: colorType,
      title: title,
      sub: sub,
      body: body,
      time: timeStr,
      type: type,
      isGlow: true,
      isTaken: false,
    );

    _notifications.insert(0, notif);
    _recalculateUnread();
    _notify();
    await _persist();
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    for (final item in _notifications) {
      item.isGlow = false;
    }
    _recalculateUnread();
    _notify();
    await _persist();
  }

  /// Mark specific notification as read/taken
  Future<void> toggleTaken(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isGlow = false;
      _notifications[index].isTaken = !_notifications[index].isTaken;
      _recalculateUnread();
      _notify();
      await _persist();
    }
  }

  /// Remove notification
  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _recalculateUnread();
    _notify();
    await _persist();
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    _recalculateUnread();
    _notify();
    await _persist();
  }
}
