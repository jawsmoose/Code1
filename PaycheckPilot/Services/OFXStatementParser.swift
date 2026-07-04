import Foundation

/// Parses OFX / QFX downloads (the Quicken/Money format most banks offer).
/// OFX is SGML-ish — closing tags are optional — so this scans <STMTTRN>
/// blocks and pulls tag values up to the next tag or line break.
enum OFXStatementParser {

    static func parse(_ text: String) -> [ParsedStatementTransaction] {
        var result: [ParsedStatementTransaction] = []

        for block in text.components(separatedBy: "<STMTTRN>").dropFirst() {
            let body = block.components(separatedBy: "</STMTTRN>").first ?? block

            guard let rawDate = value(of: "DTPOSTED", in: body),
                  let rawAmount = value(of: "TRNAMT", in: body),
                  let amount = Double(rawAmount.trimmingCharacters(in: .whitespaces)),
                  amount != 0,
                  let date = date(from: rawDate) else { continue }

            let payee = value(of: "NAME", in: body) ?? value(of: "MEMO", in: body) ?? "Unknown"
            result.append(ParsedStatementTransaction(date: date, payee: payee, amount: amount))
        }
        return result
    }

    private static func value(of tag: String, in text: String) -> String? {
        guard let range = text.range(of: "<\(tag)>") else { return nil }
        let tail = text[range.upperBound...]
        let end = tail.firstIndex { $0 == "<" || $0 == "\n" || $0 == "\r" } ?? tail.endIndex
        let value = String(tail[..<end]).trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    private static func date(from raw: String) -> Date? {
        let digits = String(raw.prefix(8))
        guard digits.count == 8 else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: digits)
    }
}
