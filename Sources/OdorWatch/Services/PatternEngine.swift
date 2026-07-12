import Foundation

/// 嗅觉模式引擎 — 分析历史数据，建立室内"正常气味基线"
final class PatternEngine: PatternEngineProtocol {

    /// 分析某房间的历史气味模式
    func analyzeRoom(_ events: [OdorEvent], for roomId: UUID) -> RoomOdorProfile {
        let roomEvents = events.filter { $0.roomId == roomId }
        let byType = Dictionary(grouping: roomEvents, by: { $0.type })

        var typeProfiles: [OdorType: TypeProfile] = [:]
        for (type, evts) in byType {
            let avgIntensity = Double(evts.reduce(0) { $0 + $1.intensity }) / Double(evts.count)
            let avgDuration = evts.compactMap { e -> TimeInterval? in
                guard let resolved = e.resolvedAt else { return nil }
                return resolved.timeIntervalSince(e.detectedAt)
            }.reduce(0, +) / Double(evts.count)

            // 频率：每月发生次数
            let daysSpan = max(1, (Date().timeIntervalSince(evts.map(\.detectedAt).min() ?? Date())) / 86400)
            let monthlyFreq = (Double(evts.count) / daysSpan) * 30

            typeProfiles[type] = TypeProfile(
                type: type,
                averageIntensity: avgIntensity,
                averageDuration: avgDuration,
                monthlyFrequency: monthlyFreq,
                totalEvents: evts.count
            )
        }

        return RoomOdorProfile(roomId: roomId, typeProfiles: typeProfiles)
    }

    /// 判断一个新事件是否"异常"
    func isAnomalous(_ event: OdorEvent, against profile: RoomOdorProfile) -> AnomalyAssessment {
        guard let p = profile.typeProfiles[event.type] else {
            // 该房间从未出现过此类气味 → 异常
            return AnomalyAssessment(
                isAnomalous: true,
                severity: event.type.dangerLevel >= 4 ? .critical : .warning,
                reason: "这是「\(event.type.rawValue)」首次在房间中被记录",
                suggestion: "密切关注，如有加重请按指引排查"
            )
        }

        var reasons: [String] = []
        var score = 0

        // 强度异常（超过历史均值 1.5 倍）
        if Double(event.intensity) > p.averageIntensity * 1.5 {
            reasons.append("强度明显高于平时（\(event.intensity)/5 vs 平时 \(String(format: "%.1f", p.averageIntensity))/5）")
            score += 3
        }

        // 频率异常（本月次数超过历史月均 2 倍）
        if p.monthlyFrequency > 0 && p.monthlyFrequency * 2 < Double(p.totalEvents) {
            reasons.append("出现频率高于正常水平")
            score += 2
        }

        // 高危类型
        if event.type.dangerLevel >= 4 {
            reasons.append("此类型气味属于高危类别")
            score += 2
        }

        if event.intensity >= 4 {
            reasons.append("气味强度高（\(event.intensity)/5）")
            score += 1
        }

        return AnomalyAssessment(
            isAnomalous: score >= 2,
            severity: score >= 5 ? .critical : score >= 3 ? .warning : .info,
            reason: reasons.joined(separator: "；"),
            suggestion: event.type.guidance.first ?? "请按指引排查"
        )
    }
}

struct RoomOdorProfile {
    let roomId: UUID
    var typeProfiles: [OdorType: TypeProfile] = [:]

    var dominantTypes: [OdorType] {
        typeProfiles.values
            .sorted { $0.totalEvents > $1.totalEvents }
            .prefix(3)
            .map(\.type)
    }
}

struct TypeProfile {
    let type: OdorType
    let averageIntensity: Double
    let averageDuration: TimeInterval
    let monthlyFrequency: Double
    let totalEvents: Int
}

struct AnomalyAssessment {
    let isAnomalous: Bool
    let severity: AnomalySeverity
    let reason: String
    let suggestion: String

    enum AnomalySeverity: String { case info = "提示", warning = "⚠️ 异常", critical = "🚨 危险" }
}
