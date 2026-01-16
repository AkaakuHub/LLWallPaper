using System.Collections.Generic;

namespace LLWallPaper.App.Utils;

public static class CharacterMap
{
    private static readonly IReadOnlyDictionary<string, string> Map = new Dictionary<string, string>
    {
        ["1011"] = "大賀美沙知",
        ["1021"] = "乙宗梢",
        ["1022"] = "夕霧綴理",
        ["1023"] = "藤島慈",
        ["1031"] = "日野下花帆",
        ["1032"] = "村野さやか",
        ["1033"] = "大沢瑠璃乃",
        ["1041"] = "百生吟子",
        ["1042"] = "徒町小鈴",
        ["1043"] = "安養寺姫芽",
        ["1051"] = "桂城泉",
        ["1052"] = "セラス 柳田 リリエンフェルト",
    };

    public static string GetNameForId(string? cardId)
    {
        if (string.IsNullOrWhiteSpace(cardId) || cardId.Length < 4)
        {
            return "その他";
        }

        var prefix = cardId[..4];
        return Map.TryGetValue(prefix, out var name) ? name : "その他";
    }

    public static bool IsSrCard(string? cardId)
    {
        if (string.IsNullOrWhiteSpace(cardId) || cardId.Length < 6)
        {
            return false;
        }

        return cardId[4..6] == "30";
    }
}
