let designTokensColorsSource = """
    public enum DSColors {
        public enum Black {
            public static let solid = Color(r: 0, g: 0, b: 0)
            public static let opacity10 = Color(r: 0, g: 0, b: 0, a: 0.1)
            public static let opacity20 = Color(r: 0, g: 0, b: 0, a: 0.2)
            public static let opacity30 = Color(r: 0, g: 0, b: 0, a: 0.3)
            public static let opacity40 = Color(r: 0, g: 0, b: 0, a: 0.4)
            public static let opacity50 = Color(r: 0, g: 0, b: 0, a: 0.5)
            public static let opacity60 = Color(r: 0, g: 0, b: 0, a: 0.6)
            public static let opacity70 = Color(r: 0, g: 0, b: 0, a: 0.7)
            public static let opacity80 = Color(r: 0, g: 0, b: 0, a: 0.8)
            public static let opacity90 = Color(r: 0, g: 0, b: 0, a: 0.9)
            public static let opacity100 = Color(r: 0, g: 0, b: 0)
        }
        public enum White {
            public static let solid = Color(r: 255, g: 255, b: 255)
            public static let opacity10 = Color(r: 255, g: 255, b: 255, a: 0.1)
            public static let opacity20 = Color(r: 255, g: 255, b: 255, a: 0.2)
            public static let opacity30 = Color(r: 255, g: 255, b: 255, a: 0.3)
            public static let opacity40 = Color(r: 255, g: 255, b: 255, a: 0.4)
            public static let opacity50 = Color(r: 255, g: 255, b: 255, a: 0.5)
            public static let opacity60 = Color(r: 255, g: 255, b: 255, a: 0.6)
            public static let opacity70 = Color(r: 255, g: 255, b: 255, a: 0.7)
            public static let opacity80 = Color(r: 255, g: 255, b: 255, a: 0.8)
            public static let opacity90 = Color(r: 255, g: 255, b: 255, a: 0.9)
            public static let opacity100 = Color(r: 255, g: 255, b: 255)
        }
    }
    """

let designTokensGridsSource = """
    public enum DSGrids {
        public enum Desktop {
            public static let columns2 = GridToken(
                columns: 2, gutter: 32, margin: 0, totalWidth: 1280
            )
            public static let columns4 = GridToken(
                columns: 4, gutter: 32, margin: 0, totalWidth: 1280
            )
            public static let columns6 = GridToken(
                columns: 6, gutter: 32, margin: 0, totalWidth: 1280
            )
            public static let columns12 = GridToken(
                columns: 12, gutter: 32, margin: 0, totalWidth: 1280
            )
        }
    }
    """
