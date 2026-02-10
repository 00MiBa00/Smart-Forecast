import 'package:flutter/foundation.dart';

class PushRequestData {
  bool? pushNotificationAccepted;
  String? pushDeclinedAt;
  bool? firstLaunch;

  void Print() {
    if (kDebugMode) {
      print(' pushNotificationAccepted=${pushNotificationAccepted} \n' +
          'pushDeclinedAt=${pushDeclinedAt}');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationAccepted': pushNotificationAccepted,
      'pushDeclinedAt': pushDeclinedAt,
      'firstLaunch': firstLaunch,
    };
  }

  PushRequestData(
      {this.pushNotificationAccepted, this.pushDeclinedAt, this.firstLaunch});

  factory PushRequestData.fromJson(Map<String, dynamic> json) {
    // var data = PushRequestData();
    // if (json.containsKey('firstLaunch')) {
    //   data.firstLaunch = json['firstLaunch'];
    // }
    var data = PushRequestData(
      pushNotificationAccepted: json['pushNotificationAccepted'],
      pushDeclinedAt: json['pushDeclinedAt'],
      firstLaunch: json['firstLaunch'],
    );
    data.Print();
    return data;
  }
}

class PushRequestControl {
  static bool isDebug = kDebugMode;

  static bool shouldShowPushRequest(PushRequestData data) {
    // Проверяем, получено ли согласие на уведомления
    final pushAccepted = data.pushNotificationAccepted;
    final firstDeclinedAt = data.pushDeclinedAt;

    // Если пользователь уже дал согласие, не показываем запрос
    if (pushAccepted == true) {
      if (isDebug) print("pushAccepted == true");
      return false;
    }

    // Если согласие не было получено и отказ не фиксировался, показываем запрос впервые
    if (pushAccepted == null && firstDeclinedAt == null) {
      if (isDebug) print("pushAccepted == null && firstDeclinedAt == null");
      return true;
    }

    // Если согласие не было получено, но есть дата первого отказа
    if (pushAccepted == false && firstDeclinedAt != null) {
      if (isDebug) print("pushAccepted == false && firstDeclinedAt != null");
      DateTime? declinedAt;
      try {
        declinedAt = DateTime.parse(firstDeclinedAt);
      } catch (e) {
        if (isDebug) print("Error parsing decline date: $e");
        return true;
      }
      final now = DateTime.now();
      final daysSinceDecline = now.difference(declinedAt).inDays;

      if (isDebug) {
        print("Days since decline: $daysSinceDecline (need 3 to show again)");
      }

      if (daysSinceDecline >= 3) {
        if (isDebug) print("3 days passed, showing push request again");
        return true;
      }

      if (isDebug) print("Less than 3 days, not showing push request");
      return false;
    }

    // Прочие случаи -- не показываем запрос
    return false;
  }

  // Метод для сохранения согласия пользователя на push-уведомления
  static void acceptPushRequest(PushRequestData data) async {
    data.pushNotificationAccepted = true;
    data.pushDeclinedAt = "";
    if (isDebug) {
      print('pushNotificationAccepted \n'
              'pushNotificationAccepted=${data.pushNotificationAccepted} \n' +
          'pushDeclinedAt=${data.pushDeclinedAt}');
    }
  }

  // Метод для сохранения отказа пользователя от push-уведомлений
  static void declinePushRequest(PushRequestData data, [DateTime? date]) {
    date ??= DateTime.now(); //.subtract(const Duration(days: 4));
    data.pushNotificationAccepted = false;
    data.pushDeclinedAt = date.toIso8601String();
    if (isDebug) {
      print('pushNotificationDecline \n' +
          'date=$date \n' +
          'pushNotificationAccepted=${data.pushNotificationAccepted} \n' +
          'pushDeclinedAt=${data.pushDeclinedAt}\n');
    }
  }
}
