struct TilingState {

    init(sizeA: Int, sizeB: Int) {
        self.markedA = [Bool](repeating: false, count: sizeA)
        self.markedB = [Bool](repeating: false, count: sizeB)
    }

    var markedA: [Bool]
    var markedB: [Bool]
    var totalCovered: Int = 0
}
