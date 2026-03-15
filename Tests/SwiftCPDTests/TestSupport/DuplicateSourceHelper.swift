import Foundation

let standardDuplicateSource = """
    func calculate() -> Int {
        let value = 42
        let result = value * 2
        let adjusted = result + 10
        let final = adjusted - 5
        return final
    }
    """

let additionalDuplicateSource = """
    func compute() -> Int {
        let input = 100
        let output = input * 3
        let adjusted = output + 20
        let shifted = adjusted - 10
        return shifted
    }
    """

let integrationDuplicateSource = """
    func calculate() -> Int {
        let value = 42
        let result = value * 2
        let adjusted = result + 10
        let final1 = adjusted - 5
        let extra = final1 + 100
        let bonus = extra * 3
        let penalty = bonus / 2
        let total = penalty - 7
        return total
    }
    """

let uniqueSourceA = """
    func greet() -> String {
        return "hello"
    }
    """

let uniqueSourceB = """
    func farewell() -> Int {
        return 99
    }
    """

func writeDuplicateFiles(
    in directory: String,
    source: String = standardDuplicateSource
) {
    try? source.write(
        toFile: directory + "/A.swift",
        atomically: true,
        encoding: .utf8
    )
    try? source.write(
        toFile: directory + "/B.swift",
        atomically: true,
        encoding: .utf8
    )
}
