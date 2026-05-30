import 'dart:convert';

class UtilityAnalysis {
  final int roomId;
  final int month;
  final int year;
  final int warningCount;
  final MeterAnalysis electric;
  final MeterAnalysis water;
  final List<String> warnings;
  final AiAnalysisInsight? aiAnalysis;

  const UtilityAnalysis({
    required this.roomId,
    required this.month,
    required this.year,
    required this.warningCount,
    required this.electric,
    required this.water,
    required this.warnings,
    this.aiAnalysis,
  });

  factory UtilityAnalysis.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    return UtilityAnalysis(
      roomId: int.tryParse('${json['room_id']}') ?? 0,
      month: json['month'] as int? ?? 0,
      year: json['year'] as int? ?? 0,
      warningCount: summary['warning'] as int? ?? 0,
      electric: MeterAnalysis.fromJson(
        json['electric'] as Map<String, dynamic>? ?? {},
        unit: 'kWh',
      ),
      water: MeterAnalysis.fromJson(
        json['water'] as Map<String, dynamic>? ?? {},
        unit: 'm³',
      ),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      aiAnalysis: AiAnalysisInsight.fromDynamic(json['ai_analysis']),
    );
  }
}

class AiAnalysisInsight {
  final String summary;
  final List<String> possibleCauses;
  final List<String> recommendations;

  const AiAnalysisInsight({
    required this.summary,
    required this.possibleCauses,
    required this.recommendations,
  });

  bool get hasContent =>
      summary.isNotEmpty ||
      possibleCauses.isNotEmpty ||
      recommendations.isNotEmpty;

  static AiAnalysisInsight? fromDynamic(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map) {
      return _fromMap(Map<String, dynamic>.from(raw));
    }

    if (raw is String && raw.trim().isNotEmpty) {
      return _fromJsonString(raw);
    }

    return null;
  }

  static AiAnalysisInsight _fromMap(Map<String, dynamic> map) {
    var summary = map['summary']?.toString().trim() ?? '';
    var causes = _parseStringList(map['possible_causes']);
    var recommendations = _parseStringList(map['recommendations']);

    // summary đôi khi chứa cả JSON thô — parse lại
    if (summary.startsWith('{') && causes.isEmpty && recommendations.isEmpty) {
      final nested = _fromJsonString(summary);
      if (nested != null && nested.hasContent) {
        return nested;
      }
    }

    return AiAnalysisInsight(
      summary: summary,
      possibleCauses: causes,
      recommendations: recommendations,
    );
  }

  static AiAnalysisInsight? _fromJsonString(String raw) {
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final candidates = <String>[cleaned];
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start != -1 && end > start) {
      candidates.insert(0, cleaned.substring(start, end + 1));
    }

    for (final candidate in candidates) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map) {
          return _fromMap(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        continue;
      }
    }

    if (cleaned.startsWith('{')) return null;

    return AiAnalysisInsight(
      summary: cleaned,
      possibleCauses: const [],
      recommendations: const [],
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class MeterAnalysis {
  final String status;
  final num meterOld;
  final num meterNew;
  final num currentUsage;
  final num previousUsage;
  final double changePercent;
  final num average6Months;
  final List<HistoryPoint> history;

  const MeterAnalysis({
    required this.status,
    required this.meterOld,
    required this.meterNew,
    required this.currentUsage,
    required this.previousUsage,
    required this.changePercent,
    required this.average6Months,
    required this.history,
  });

  factory MeterAnalysis.fromJson(Map<String, dynamic> json, {required String unit}) {
    final historyDetail = json['history_detail'] as List<dynamic>?;
    final rawHistory = json['history'] as List<dynamic>? ?? [];

    List<HistoryPoint> history;
    if (historyDetail != null && historyDetail.isNotEmpty) {
      history = historyDetail
          .map((e) => HistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      history = rawHistory.asMap().entries.map((entry) {
        return HistoryPoint(
          label: 'T${entry.key + 1}',
          usage: (entry.value as num?) ?? 0,
        );
      }).toList();
    }

    return MeterAnalysis(
      status: json['status'] as String? ?? 'normal',
      meterOld: (json['meter_old'] as num?) ?? 0,
      meterNew: (json['meter_new'] as num?) ?? 0,
      currentUsage: (json['current_usage'] as num?) ?? 0,
      previousUsage: (json['previous_usage'] as num?) ?? 0,
      changePercent: ((json['change_percent'] as num?) ?? 0).toDouble(),
      average6Months: (json['average_6_months'] as num?) ?? 0,
      history: history,
    );
  }

  bool get isWarning => status == 'warning';
  String get statusLabel => isWarning ? 'CẢNH BÁO' : 'BÌNH THƯỜNG';
}

class HistoryPoint {
  final String label;
  final num usage;
  final int? month;
  final int? year;

  const HistoryPoint({
    required this.label,
    required this.usage,
    this.month,
    this.year,
  });

  factory HistoryPoint.fromJson(Map<String, dynamic> json) {
    return HistoryPoint(
      label: json['label'] as String? ?? 'T${json['month']}',
      usage: (json['usage'] as num?) ?? 0,
      month: json['month'] as int?,
      year: json['year'] as int?,
    );
  }
}
