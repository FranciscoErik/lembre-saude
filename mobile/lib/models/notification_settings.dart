class NotificationSettings {
  const NotificationSettings({
    required this.enabled,
    required this.remindBeforeMinutes,
  });

  final bool enabled;
  final int remindBeforeMinutes;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      remindBeforeMinutes: json['remindBeforeMinutes'] as int? ?? 0,
    );
  }
}
