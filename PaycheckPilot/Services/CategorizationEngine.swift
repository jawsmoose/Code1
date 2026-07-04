import Foundation

/// Rules-based auto-categorization for imported statement transactions.
/// The first rule whose keyword appears in the payee wins; users can
/// recategorize any transaction by hand afterwards.
enum CategorizationEngine {

    private static let rules: [(keywords: [String], category: SpendingCategory)] = [
        // Money in
        (["payroll", "direct dep", "dir dep", "salary", "gusto", "adp", "paychex"], .income),

        // Debt & transfers
        (["mortgage", " mtg", "lending", "loan pmt", "loan payment", "navient", "nelnet", "sallie mae",
          "autopay", "card payment", "payment thank you", "cardmember serv"], .debtPayment),
        (["vanguard", "fidelity", "schwab", "robinhood", "etrade", "e*trade", "brokerage",
          "401k", "401(k)", "betterment", "wealthfront", "acorns"], .investment),
        (["transfer to savings", "savings transfer", "goal transfer", "ally bank", "marcus"], .savingsTransfer),

        // Essentials
        (["rent", "apartment", "property mgmt", "hoa "], .housing),
        (["electric", "power co", "energy", "water dept", "water util", "gas co", "sewer",
          "comcast", "xfinity", "spectrum", "internet", "verizon", "at&t", "t-mobile"], .utilities),
        (["kroger", "safeway", "whole foods", "trader joe", "aldi", "publix", "wegmans",
          "heb ", "grocery", "market basket", "food lion", "winco", "costco whse"], .groceries),
        (["uber trip", "lyft", "shell", "chevron", "exxon", "mobil", "marathon petro", "76 ",
          "gas station", "parking", "metro", "transit", "toll", "jiffy lube", "autozone"], .transport),
        (["geico", "state farm", "progressive", "allstate", "insurance", "insur"], .insurance),
        (["pharmacy", "cvs", "walgreens", "clinic", "dental", "medical", "hospital",
          "urgent care", "optometr", "kaiser"], .healthcare),
        (["tuition", "university", "college", "udemy", "coursera"], .education),

        // Discretionary
        (["netflix", "spotify", "hulu", "disney plus", "disney+", "apple.com/bill", "youtube prem",
          "hbo", "paramount+", "audible", "patreon", "prime video", "gym", "planet fit",
          "crunch fit", "peloton"], .subscriptions),
        (["mcdonald", "starbucks", "chipotle", "doordash", "uber eats", "ubereats", "grubhub",
          "restaurant", "cafe", "coffee", "pizza", "taco", "burger", "sushi", "chick-fil-a",
          "panera", "dunkin", "wendy", "subway", "brewery", "bar & grill"], .dining),
        (["amc ", "cinema", "cinemark", "ticketmaster", "stubhub", "steam", "steamgames",
          "playstation", "xbox", "nintendo", "eventbrite", "topgolf", "bowl"], .entertainment),
        (["delta air", "united air", "american air", "southwest", "alaska air", "jetblue",
          "airbnb", "vrbo", "marriott", "hilton", "hyatt", "hotel", "expedia", "booking.com",
          "hertz", "enterprise rent"], .travel),
        (["salon", "barber", "spa ", "nails", "sephora", "ulta"], .personalCare),
        (["amazon", "amzn", "target", "walmart", "best buy", "ebay", "etsy", "ikea",
          "home depot", "lowe's", "lowes", "nordstrom", "macy", "old navy", "nike",
          "shein", "temu", "wayfair"], .shopping),
    ]

    static func categorize(payee: String, amount: Double) -> SpendingCategory {
        let normalized = payee.lowercased()

        for rule in rules where rule.keywords.contains(where: { normalized.contains($0) }) {
            return rule.category
        }

        // Uncategorized deposits are treated as income; unknown spending as other.
        return amount > 0 ? .income : .other
    }
}
