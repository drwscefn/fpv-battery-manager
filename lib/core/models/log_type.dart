enum LogType {
  postCharge,
  postFlight,
  storage;

  String get label => switch (this) {
        LogType.postCharge => 'POST-CHARGE',
        LogType.postFlight => 'POST-FLIGHT',
        LogType.storage => 'STORAGE',
      };

  String get dbValue => switch (this) {
        LogType.postCharge => 'post_charge',
        LogType.postFlight => 'post_flight',
        LogType.storage => 'storage',
      };

  static LogType fromDb(String? value) => switch (value) {
        'post_flight' => LogType.postFlight,
        'storage' => LogType.storage,
        _ => LogType.postCharge,
      };
}
