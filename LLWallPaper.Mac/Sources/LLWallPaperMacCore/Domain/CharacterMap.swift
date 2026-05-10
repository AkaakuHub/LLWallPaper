import Foundation

public enum CharacterMap {
  private static let names: [String: String] = [
    "1011": "大賀美沙知",
    "1021": "乙宗梢",
    "1022": "夕霧綴理",
    "1023": "藤島慈",
    "1031": "日野下花帆",
    "1032": "村野さやか",
    "1033": "大沢瑠璃乃",
    "1041": "百生吟子",
    "1042": "徒町小鈴",
    "1043": "安養寺姫芽",
    "1051": "桂城泉",
    "1052": "セラス 柳田 リリエンフェルト",
  ]

  public static func name(for cardId: String?) -> String {
    guard let cardId, cardId.count >= 4 else {
      return "その他"
    }

    let prefix = String(cardId.prefix(4))
    return names[prefix] ?? "その他"
  }

  public static func isSrCard(_ cardId: String?) -> Bool {
    guard let cardId, cardId.count >= 6 else {
      return false
    }

    let start = cardId.index(cardId.startIndex, offsetBy: 4)
    let end = cardId.index(start, offsetBy: 2)
    return cardId[start..<end] == "30"
  }
}
