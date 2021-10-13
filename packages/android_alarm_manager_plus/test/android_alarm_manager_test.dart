// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String invalidCallback(String foo) => foo;
  // ignore: avoid_returning_null_for_void
  void validCallback(int id) => null;

  const testChannel = MethodChannel(
      'dev.fluttercommunity.plus/android_alarm_manager', JSONMethodCodec());
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    testChannel.setMockMethodCallHandler((MethodCall call) => null);
  });

  test('${AndroidAlarmManager.initialize}', () async {
    testChannel.setMockMethodCallHandler((MethodCall call) async {
      assert(call.method == 'AlarmService.start');
      return true;
    });

    final initialized = await AndroidAlarmManager.initialize();

    expect(initialized, isTrue);
  });

  group('${AndroidAlarmManager.oneShotAt}', () {
    test('validates input', () async {
      final validTime = DateTime.utc(1993);
      const validId = 1;

      // Callback should take a single int param.
      await expectLater(
          () => AndroidAlarmManager.oneShotAt(
              validTime, validId, invalidCallback),
          throwsAssertionError);

      // ID should be less than 32 bits.
      await expectLater(
          () => AndroidAlarmManager.oneShotAt(
              validTime, 2147483648, validCallback),
          throwsAssertionError);
    });

    test('sends arguments to the platform', () async {
      final alarm = DateTime(1993);
      const rawHandle = 4;
      AndroidAlarmManager.setTestOverrides(
          getCallbackHandle: (Function _) =>
              CallbackHandle.fromRawHandle(rawHandle));

      const id = 1;
      const alarmClock = true;
      const allowWhileIdle = true;
      const exact = true;
      const wakeup = true;
      const rescheduleOnReboot = true;

      testChannel.setMockMethodCallHandler((MethodCall call) async {
        expect(call.method, 'Alarm.oneShotAt');
        expect(call.arguments[0], id);
        expect(call.arguments[1], alarmClock);
        expect(call.arguments[2], allowWhileIdle);
        expect(call.arguments[3], exact);
        expect(call.arguments[4], wakeup);
        expect(call.arguments[5], alarm.millisecondsSinceEpoch);
        expect(call.arguments[6], rescheduleOnReboot);
        expect(call.arguments[7], rawHandle);
        return true;
      });

      final result = await AndroidAlarmManager.oneShotAt(
          alarm, id, validCallback,
          alarmClock: alarmClock,
          allowWhileIdle: allowWhileIdle,
          exact: exact,
          wakeup: wakeup,
          rescheduleOnReboot: rescheduleOnReboot);

      expect(result, isTrue);
    });
  });

  test('${AndroidAlarmManager.oneShot} calls through to oneShotAt', () async {
    final now = DateTime(1993);
    const rawHandle = 4;
    AndroidAlarmManager.setTestOverrides(
        now: () => now,
        getCallbackHandle: (Function _) =>
            CallbackHandle.fromRawHandle(rawHandle));

    const alarm = Duration(seconds: 1);
    const id = 1;
    const alarmClock = true;
    const allowWhileIdle = true;
    const exact = true;
    const wakeup = true;
    const rescheduleOnReboot = true;

    testChannel.setMockMethodCallHandler((MethodCall call) async {
      expect(call.method, 'Alarm.oneShotAt');
      expect(call.arguments[0], id);
      expect(call.arguments[1], alarmClock);
      expect(call.arguments[2], allowWhileIdle);
      expect(call.arguments[3], exact);
      expect(call.arguments[4], wakeup);
      expect(
          call.arguments[5], now.millisecondsSinceEpoch + alarm.inMilliseconds);
      expect(call.arguments[6], rescheduleOnReboot);
      expect(call.arguments[7], rawHandle);
      return true;
    });

    final result = await AndroidAlarmManager.oneShot(alarm, id, validCallback,
        alarmClock: alarmClock,
        allowWhileIdle: allowWhileIdle,
        exact: exact,
        wakeup: wakeup,
        rescheduleOnReboot: rescheduleOnReboot);

    expect(result, isTrue);
  });

  group('${AndroidAlarmManager.periodic}', () {
    test('validates input', () async {
      const validDuration = Duration(seconds: 0);
      const validId = 1;

      // Callback should take a single int param.
      await expectLater(
          () => AndroidAlarmManager.periodic(
              validDuration, validId, invalidCallback),
          throwsAssertionError);

      // ID should be less than 32 bits.
      await expectLater(
          () => AndroidAlarmManager.periodic(
              validDuration, 2147483648, validCallback),
          throwsAssertionError);
    });

    test('sends arguments through to the platform', () async {
      final now = DateTime(1993);
      const rawHandle = 4;
      AndroidAlarmManager.setTestOverrides(
          now: () => now,
          getCallbackHandle: (Function _) =>
              CallbackHandle.fromRawHandle(rawHandle));

      const id = 1;
      const allowWhileIdle = true;
      const exact = true;
      const wakeup = true;
      const rescheduleOnReboot = true;
      const period = Duration(seconds: 1);

      testChannel.setMockMethodCallHandler((MethodCall call) async {
        expect(call.method, 'Alarm.periodic');
        expect(call.arguments[0], id);
        expect(call.arguments[1], allowWhileIdle);
        expect(call.arguments[2], exact);
        expect(call.arguments[3], wakeup);
        expect(call.arguments[4],
            (now.millisecondsSinceEpoch + period.inMilliseconds));
        expect(call.arguments[5], period.inMilliseconds);
        expect(call.arguments[6], rescheduleOnReboot);
        expect(call.arguments[7], rawHandle);
        return true;
      });

      final result = await AndroidAlarmManager.periodic(
        period,
        id,
        (int id) => null,
        allowWhileIdle: allowWhileIdle,
        exact: exact,
        wakeup: wakeup,
        rescheduleOnReboot: rescheduleOnReboot,
      );

      expect(result, isTrue);
    });
  });

  test('${AndroidAlarmManager.cancel}', () async {
    const id = 1;
    testChannel.setMockMethodCallHandler((MethodCall call) async {
      assert(call.method == 'Alarm.cancel' && call.arguments[0] == id);
      return true;
    });

    final canceled = await AndroidAlarmManager.cancel(id);

    expect(canceled, isTrue);
  });
}
