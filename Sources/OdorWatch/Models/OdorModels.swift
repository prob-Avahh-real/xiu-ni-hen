import Foundation
import SwiftUI

// MARK: - Odor Type

enum OdorType: String, CaseIterable, Codable {
    case smoke      = "烟味"
    case gas        = "煤气味"
    case mold       = "霉味"
    case chemical   = "化学品"
    case burning    = "焦糊味"
    case sewage     = "下水道"
    case pet        = "宠物异味"
    case food       = "食物腐败"
    case perfume    = "异常香味"
    case unknown    = "说不清"

    var icon: String {
        switch self {
        case .smoke:     "🔥"
        case .gas:       "⚠️"
        case .mold:      "🦠"
        case .chemical:  "🧪"
        case .burning:   "🔌"
        case .sewage:    "🚿"
        case .pet:       "🐾"
        case .food:      "🗑️"
        case .perfume:   "🌸"
        case .unknown:   "❓"
        }
    }

    var color: Color {
        switch self {
        case .smoke:     .orange
        case .gas:       .red
        case .mold:      .green
        case .chemical:  .purple
        case .burning:   .red
        case .sewage:    .brown
        case .pet:       .yellow
        case .food:      .orange
        case .perfume:   .pink
        case .unknown:   .gray
        }
    }

    var dangerLevel: Int {
        switch self {
        case .gas, .burning:           5  // 立即行动
        case .smoke, .chemical:        4  // 高度警惕
        case .sewage, .mold:           3  // 需要关注
        case .food, .unknown:          2  // 留意
        case .pet, .perfume:           1  // 一般
        }
    }

    var guidance: [String] {
        switch self {
        case .gas:
            return ["立即打开门窗通风", "不要开关任何电器或明火", "检查燃气灶阀门是否关闭", "撤离到室外后拨打燃气公司电话", "不要试图自己修复管道"]
        case .smoke:
            return ["确认是否有明火或冒烟点", "检查厨房灶具是否关闭", "检查电器插头是否过热", "如有明火立即使用灭火器", "火势失控时立即撤离并拨打119"]
        case .burning:
            return ["检查所有正在运行的电器", "闻一闻插座和延长线附近", "检查配电箱是否有焦痕", "关闭可疑电器的电源", "联系电工检查线路"]
        case .mold:
            return ["检查浴室、厨房的墙角", "查看空调出风口是否有霉斑", "检查水槽下方是否有漏水", "查看窗框密封条是否发霉", "考虑购买除湿机"]
        case .chemical:
            return ["检查是否刚使用清洁剂", "查看装修材料是否释放甲醛", "确认通风是否充足", "考虑使用空气净化器", "持续刺鼻需联系物业"]
        case .sewage:
            return ["检查所有地漏是否有水封", "查看马桶密封圈是否老化", "检查洗手盆下水管是否堵塞", "查看阳台排水口", "联系物业检查主排水管"]
        case .food:
            return ["检查冰箱内是否有过期食物", "查看橱柜是否有变质干货", "清理垃圾桶", "检查水槽残渣处理器", "清洗微波炉内壁"]
        case .pet:
            return ["检查宠物活动区域", "清洗宠物窝垫", "查看猫砂盆是否需要清理", "检查宠物是否在隐蔽处排泄", "给宠物洗澡"]
        case .perfume:
            return ["确认是否有陌生人进入", "检查窗户是否未关", "查看是否有不明液体洒落", "提高警惕，注意其他异常", "持续出现联系物业或安保"]
        case .unknown:
            return ["在室内走一圈定位气味来源", "检查每个房间的通风情况", "留意是否有其他异常现象", "记录气味出现的规律", "持续出现建议安装空气检测仪"]
        }
    }
}

// MARK: - Room

struct Room: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var icon: String          // SF Symbol name
    var floor: Int            // 楼层（0=地下室）
    var sizeSqm: Double?      // 面积
    var hasWindow: Bool = true
    var hasVentilation: Bool = false
    var airQualityDeviceId: String?  // HomeKit accessory UUID
}

// MARK: - Odor Event

struct OdorEvent: Identifiable, Codable {
    var id = UUID()
    var type: OdorType
    var intensity: Int        // 1-5
    var roomId: UUID
    var detectedAt: Date
    var resolvedAt: Date?
    var notes: String?
    var isEmergency: Bool
    var temperature: Double?  // 关联的环境数据
    var humidity: Double?
}

// MARK: - Air Quality Reading

struct AirQualityReading: Identifiable, Codable {
    var id = UUID()
    var timestamp: Date
    var vocIndex: Double?       // 挥发性有机物
    var pm2_5: Double?          // 细颗粒物
    var pm10: Double?           // 可吸入颗粒物
    var co2: Double?            // 二氧化碳 ppm
    var temperature: Double?
    var humidity: Double?
    var roomId: UUID

    var overallQuality: AirQuality { .init(voc: vocIndex, pm25: pm2_5, co2: co2) }
}

struct AirQuality {
    let voc: Double?
    let pm25: Double?
    let co2: Double?

    enum Level: String { case good = "优", fair = "良", moderate = "一般", poor = "差", bad = "严重" }

    var level: Level {
        let scores = [vocScore, pm25Score, co2Score]
        let avg = scores.reduce(0, +) / Double(scores.count)
        switch avg {
        case ..<1: return .good
        case ..<2: return .fair
        case ..<3: return .moderate
        case ..<4: return .poor
        default: return .bad
        }
    }

    private var vocScore: Double {
        guard let v = voc else { return 2 }
        switch v {
        case ..<50: return 0
        case ..<100: return 1
        case ..<200: return 2
        case ..<400: return 3
        default: return 4
        }
    }
    private var pm25Score: Double {
        guard let p = pm25 else { return 2 }
        switch p {
        case ..<12: return 0
        case ..<35: return 1
        case ..<55: return 2
        case ..<150: return 3
        default: return 4
        }
    }
    private var co2Score: Double {
        guard let c = co2 else { return 2 }
        switch c {
        case ..<600: return 0
        case ..<1000: return 1
        case ..<1500: return 2
        case ..<2000: return 3
        default: return 4
        }
    }
}

// MARK: - Alert Rule

struct AlertRule: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isEnabled: Bool = true
    var odorTypes: [OdorType] = []
    var minIntensity: Int = 3
    var notifyImmediately: Bool = true
    var cooldownMinutes: Int = 30   // 同类型告警冷却时间
}

// MARK: - User Preferences

struct QuietHours: Codable, Equatable {
    var start: Int = 22
    var end: Int = 7
}

struct OdorPreferences: Codable {
    var rooms: [Room] = [
        Room(name: "客厅", icon: "sofa.fill", floor: 0, hasWindow: true),
        Room(name: "厨房", icon: "fork.knife", floor: 0, hasWindow: true, hasVentilation: true),
        Room(name: "卧室", icon: "bed.double.fill", floor: 1, hasWindow: true),
        Room(name: "卫生间", icon: "shower.fill", floor: 0, hasWindow: false, hasVentilation: true),
        Room(name: "阳台", icon: "sun.max.fill", floor: 0, hasWindow: true),
    ]
    var alertRules: [AlertRule] = AlertRule.defaults
    var emergencyContacts: [String] = []
    var sendEmergencyAlert: Bool = false
    var notificationQuietHours: QuietHours = QuietHours()
}

extension AlertRule {
    static let defaults: [AlertRule] = [
        AlertRule(name: "燃气泄漏", odorTypes: [.gas], minIntensity: 1, notifyImmediately: true, cooldownMinutes: 5),
        AlertRule(name: "火灾风险", odorTypes: [.smoke, .burning], minIntensity: 2, notifyImmediately: true, cooldownMinutes: 10),
        AlertRule(name: "化学品泄漏", odorTypes: [.chemical], minIntensity: 3, notifyImmediately: true, cooldownMinutes: 30),
        AlertRule(name: "卫生问题", odorTypes: [.sewage, .mold, .food, .pet], minIntensity: 3, notifyImmediately: false, cooldownMinutes: 120),
    ]
}
