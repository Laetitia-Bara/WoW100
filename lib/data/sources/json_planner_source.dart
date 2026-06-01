import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/tracking_item.dart';

class JsonPlannerSource {
  Future<List<TrackingItem>> loadWrathMounts() async {
    final jsonString = await rootBundle.loadString(
      'assets/data/mounts/wrath_mounts.json',
    );

    final List<dynamic> data = jsonDecode(jsonString);

    return data
        .map((e) => TrackingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
