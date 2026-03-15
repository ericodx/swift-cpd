enum CLanguageVocabulary {

    static let cKeywords: Set<String> = [
        "if", "else", "for", "while", "switch", "case", "return",
        "break", "continue", "do", "typedef", "struct", "enum",
        "union", "void", "int", "float", "double", "char", "long",
        "short", "unsigned", "signed", "const", "static", "extern",
        "sizeof", "goto", "default", "volatile", "register", "auto",
        "inline", "true", "false",
    ]

    static let objcKeywords: Set<String> = [
        "nil", "YES", "NO", "self", "super",
    ]

    static let objcAtKeywords: Set<String> = [
        "@interface", "@implementation", "@property", "@synthesize",
        "@end", "@protocol", "@selector", "@class", "@optional",
        "@required", "@dynamic", "@encode", "@synchronized",
        "@autoreleasepool", "@try", "@catch", "@finally", "@throw",
    ]

    static let knownTypeNames: Set<String> = [
        "NSArray", "NSMutableArray", "NSString", "NSMutableString",
        "NSDictionary", "NSMutableDictionary", "NSNumber", "NSObject",
        "NSInteger", "NSUInteger", "CGFloat", "BOOL", "id",
        "NSSet", "NSMutableSet", "NSData", "NSMutableData",
        "NSError", "NSURL", "NSDate", "NSValue", "NSNull",
    ]

    static let operatorStartCharacters: Set<Character> = [
        "+", "-", "*", "/", "%", "=", "!", "<", ">",
        "&", "|", "^", "~",
    ]

    static let punctuationCharacters: Set<Character> = [
        "{", "}", "(", ")", "[", "]", ";", ",", ".", ":", "?",
    ]

    static let twoCharOperators: Set<String> = [
        "==", "!=", "<=", ">=", "&&", "||", "++", "--",
        "+=", "-=", "*=", "/=", "->", "<<", ">>",
    ]

    static func classifyWord(_ text: String) -> TokenKind {
        if cKeywords.contains(text) || objcKeywords.contains(text) {
            return .keyword
        }

        if knownTypeNames.contains(text) {
            return .typeName
        }

        if let first = text.first, first.isUppercase {
            return .typeName
        }

        return .identifier
    }
}
