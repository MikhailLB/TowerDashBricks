import Foundation

/// Blueprint puzzle (nonogram) level data. The art is authored as rows of
/// characters: `#` = brick, anything else = gap. Direct port of the Dart model.
struct PuzzleLevel: Identifiable, Hashable {
    let levelNumber: Int
    let name: String
    let rowsArt: [String]
    let coinReward: Int
    let lives: Int

    var id: Int { levelNumber }

    let rowCount: Int
    let colCount: Int
    let brickCount: Int
    let rowClues: [[Int]]
    let colClues: [[Int]]

    init(levelNumber: Int, name: String, coinReward: Int, lives: Int, rowsArt: [String]) {
        self.levelNumber = levelNumber
        self.name = name
        self.coinReward = coinReward
        self.lives = lives
        self.rowsArt = rowsArt

        let rows = rowsArt.count
        let cols = rowsArt.first?.count ?? 0
        self.rowCount = rows
        self.colCount = cols

        let chars = rowsArt.map { Array($0) }
        var bricks = 0
        for row in chars { for ch in row where ch == "#" { bricks += 1 } }
        self.brickCount = bricks

        func runs(_ filled: (Int) -> Bool, _ length: Int) -> [Int] {
            var result: [Int] = []
            var current = 0
            for i in 0..<length {
                if filled(i) {
                    current += 1
                } else if current > 0 {
                    result.append(current)
                    current = 0
                }
            }
            if current > 0 { result.append(current) }
            return result.isEmpty ? [0] : result
        }

        self.rowClues = (0..<rows).map { r in
            runs({ c in chars[r][c] == "#" }, cols)
        }
        self.colClues = (0..<cols).map { c in
            runs({ r in chars[r][c] == "#" }, rows)
        }
    }

    func solutionAt(_ r: Int, _ c: Int) -> Bool {
        Array(rowsArt[r])[c] == "#"
    }
}

enum PuzzleLevels {
    static let all: [PuzzleLevel] = [
        PuzzleLevel(levelNumber: 1, name: "Window Frame", coinReward: 50, lives: 3, rowsArt: [
            "#####",
            "#...#",
            "#...#",
            "#...#",
            "#####",
        ]),
        PuzzleLevel(levelNumber: 2, name: "Crane Hook", coinReward: 60, lives: 3, rowsArt: [
            "..#..",
            ".###.",
            "#####",
            "..#..",
            "..#..",
        ]),
        PuzzleLevel(levelNumber: 3, name: "Keystone", coinReward: 80, lives: 3, rowsArt: [
            "..##..",
            ".####.",
            "######",
            "######",
            ".####.",
            "..##..",
        ]),
        PuzzleLevel(levelNumber: 4, name: "Brick House", coinReward: 100, lives: 4, rowsArt: [
            "..###..",
            ".#####.",
            "#######",
            "#.....#",
            "#.###.#",
            "#.#.#.#",
            "#######",
        ]),
        PuzzleLevel(levelNumber: 5, name: "Master Key", coinReward: 130, lives: 4, rowsArt: [
            "..####..",
            ".#....#.",
            ".#....#.",
            "..####..",
            "...##...",
            "...##...",
            "...###..",
            "...##...",
        ]),
        PuzzleLevel(levelNumber: 6, name: "Foreman Star", coinReward: 160, lives: 4, rowsArt: [
            "...##...",
            "...##...",
            "########",
            ".######.",
            "..####..",
            ".######.",
            ".#....#.",
            "##....##",
        ]),
        PuzzleLevel(levelNumber: 7, name: "Heart of the City", coinReward: 200, lives: 5, rowsArt: [
            "..##..##..",
            ".########.",
            "##########",
            "##########",
            "##########",
            ".########.",
            ".########.",
            "..######..",
            "...####...",
            "....##....",
        ]),
        PuzzleLevel(levelNumber: 8, name: "Skyscraper", coinReward: 240, lives: 5, rowsArt: [
            "...####...",
            "...####...",
            "..######..",
            "..#.##.#..",
            "..######..",
            "..#.##.#..",
            "..######..",
            ".########.",
            "#.######.#",
            "##########",
        ]),
        PuzzleLevel(levelNumber: 9, name: "Gear Works", coinReward: 300, lives: 5, rowsArt: [
            "...####...",
            ".#.####.#.",
            ".########.",
            "###.##.###",
            "##......##",
            "##......##",
            "###.##.###",
            ".########.",
            ".#.####.#.",
            "...####...",
        ]),
        PuzzleLevel(levelNumber: 10, name: "Battlements", coinReward: 400, lives: 5, rowsArt: [
            "#.#.#.#.#.",
            "##########",
            "##########",
            "#.######.#",
            "#.#....#.#",
            "#.#.##.#.#",
            "#.#.##.#.#",
            "##########",
            "##########",
            "##########",
        ]),
        PuzzleLevel(levelNumber: 11, name: "Safety Cross", coinReward: 450, lives: 5, rowsArt: [
            "....###....",
            "....###....",
            "....###....",
            "....###....",
            "###########",
            "###########",
            "###########",
            "....###....",
            "....###....",
            "....###....",
            "....###....",
        ]),
        PuzzleLevel(levelNumber: 12, name: "Crane Signal", coinReward: 500, lives: 5, rowsArt: [
            ".....#.....",
            "....###....",
            "...#####...",
            "..#######..",
            ".#########.",
            "###########",
            "....###....",
            "....###....",
            "....###....",
            "....###....",
            "....###....",
        ]),
        PuzzleLevel(levelNumber: 13, name: "Cut Diamond", coinReward: 550, lives: 5, rowsArt: [
            ".....##.....",
            "....####....",
            "...######...",
            "..########..",
            ".##########.",
            "############",
            "############",
            ".##########.",
            "..########..",
            "...######...",
            "....####....",
            ".....##.....",
        ]),
        PuzzleLevel(levelNumber: 14, name: "City Heart", coinReward: 600, lives: 4, rowsArt: [
            "...##..##...",
            "..########..",
            ".##########.",
            ".##########.",
            ".##########.",
            "..########..",
            "..########..",
            "...######...",
            "....####....",
            ".....##.....",
        ]),
        PuzzleLevel(levelNumber: 15, name: "Grand Tower", coinReward: 700, lives: 4, rowsArt: [
            ".....###.....",
            ".....###.....",
            "....#####....",
            "....#####....",
            "...#######...",
            "...#######...",
            "..#########..",
            "..#########..",
            ".###########.",
            ".###########.",
            "#############",
            "#############",
            "#############",
        ]),
        PuzzleLevel(levelNumber: 16, name: "Hard Hat", coinReward: 760, lives: 5, rowsArt: [
            "...#####...",
            "..#######..",
            ".#########.",
            ".#########.",
            ".#########.",
            "###########",
            "###########",
        ]),
        PuzzleLevel(levelNumber: 17, name: "Scaffold Beam", coinReward: 820, lives: 5, rowsArt: [
            "##........",
            "###.......",
            ".###......",
            "..###.....",
            "...###....",
            "....###...",
            ".....###..",
            "......###.",
            ".......###",
            "........##",
        ]),
        PuzzleLevel(levelNumber: 18, name: "Sledgehammer", coinReward: 880, lives: 5, rowsArt: [
            "#########",
            "#########",
            "#########",
            "...###...",
            "...###...",
            "...###...",
            "...###...",
            "...###...",
            "...###...",
            "...###...",
            "...###...",
        ]),
        PuzzleLevel(levelNumber: 19, name: "Site Padlock", coinReward: 940, lives: 5, rowsArt: [
            "..#####..",
            ".#.....#.",
            ".#.....#.",
            ".#.....#.",
            "#########",
            "#########",
            "####.####",
            "###...###",
            "####.####",
            "#########",
            "#########",
        ]),
        PuzzleLevel(levelNumber: 20, name: "Hex Bolt", coinReward: 1000, lives: 5, rowsArt: [
            "..######..",
            ".########.",
            "##########",
            "##########",
            "##########",
            "##########",
            "##########",
            "##########",
            ".########.",
            "..######..",
        ]),
        PuzzleLevel(levelNumber: 21, name: "Tall Ladder", coinReward: 1060, lives: 5, rowsArt: [
            "#.....#",
            "#.....#",
            "#######",
            "#.....#",
            "#.....#",
            "#######",
            "#.....#",
            "#.....#",
            "#######",
            "#.....#",
            "#.....#",
            "#######",
            "#.....#",
        ]),
        PuzzleLevel(levelNumber: 22, name: "Paint Roller", coinReward: 1120, lives: 5, rowsArt: [
            "##########",
            "##########",
            "#........#",
            "##########",
            "....#.....",
            "....#.....",
            "....#.....",
            "...###....",
            "...###....",
            "...###....",
        ]),
        PuzzleLevel(levelNumber: 23, name: "Power Drill", coinReward: 1180, lives: 5, rowsArt: [
            "#######....",
            "#######....",
            "#########..",
            "##########.",
            "###########",
            "#########..",
            "#######....",
            "...##......",
            "...##......",
        ]),
        PuzzleLevel(levelNumber: 24, name: "Diamond Plate", coinReward: 1240, lives: 5, rowsArt: [
            ".....#.....",
            "....###....",
            "...#####...",
            "..#######..",
            ".#########.",
            "###########",
            ".#########.",
            "..#######..",
            "...#####...",
            "....###....",
            ".....#.....",
        ]),
        PuzzleLevel(levelNumber: 25, name: "Steel Ring", coinReward: 1300, lives: 5, rowsArt: [
            "..#######..",
            ".#########.",
            "###########",
            "####...####",
            "###.....###",
            "###.....###",
            "###.....###",
            "####...####",
            "###########",
            ".#########.",
            "..#######..",
        ]),
        PuzzleLevel(levelNumber: 26, name: "Work Truck", coinReward: 1360, lives: 6, rowsArt: [
            "......####..",
            ".....#####..",
            "..#########.",
            ".###########",
            ".###########",
            ".###########",
            ".##.....##..",
            "..#.....#...",
        ]),
        PuzzleLevel(levelNumber: 27, name: "Guard Tower", coinReward: 1420, lives: 6, rowsArt: [
            "###########",
            "#.#.#.#.#.#",
            "###########",
            ".#########.",
            ".#.......#.",
            ".#.......#.",
            ".#.......#.",
            ".#.......#.",
            ".#########.",
            "..#######..",
            "..#######..",
            "...#####...",
            "...#####...",
        ]),
        PuzzleLevel(levelNumber: 28, name: "Arch Bridge", coinReward: 1480, lives: 6, rowsArt: [
            "#############",
            "#############",
            "###.......###",
            "##.........##",
            "#...........#",
            "#...........#",
            "#...........#",
            "#...........#",
        ]),
        PuzzleLevel(levelNumber: 29, name: "Lighthouse", coinReward: 1540, lives: 6, rowsArt: [
            "...###...",
            "..#####..",
            ".#######.",
            "..#####..",
            "...###...",
            "..#####..",
            "..#.#.#..",
            "..#####..",
            ".#.#.#.#.",
            ".#######.",
            "#.#.#.#.#",
            "#########",
            "#########",
        ]),
        PuzzleLevel(levelNumber: 30, name: "Tower Crane", coinReward: 1600, lives: 6, rowsArt: [
            ".....#.......",
            ".....#.......",
            ".....#.......",
            ".....##......",
            "#############",
            "#############",
            "....##.......",
            "....##.......",
            "....##.......",
            "....##.......",
            "....##.......",
            "...####......",
            "..######.....",
        ]),
        PuzzleLevel(levelNumber: 31, name: "Castle Gate", coinReward: 1660, lives: 6, rowsArt: [
            "##.##.##.##",
            "###########",
            "###########",
            "####...####",
            "###.....###",
            "###.....###",
            "###.....###",
            "###.....###",
            "###########",
        ]),
        PuzzleLevel(levelNumber: 32, name: "Gear Wheel", coinReward: 1720, lives: 6, rowsArt: [
            "...#....#...",
            "...######...",
            "..########..",
            ".##########.",
            "#.########.#",
            "#.###..###.#",
            "#.###..###.#",
            "#.########.#",
            ".##########.",
            "..########..",
            "...######...",
            "...#....#...",
        ]),
        PuzzleLevel(levelNumber: 33, name: "Pyramid Site", coinReward: 1780, lives: 6, rowsArt: [
            "......#......",
            ".....###.....",
            "....#####....",
            "...#######...",
            "..#########..",
            ".###########.",
            "#############",
            "#############",
            "#####...#####",
            "#####...#####",
            "#####...#####",
        ]),
        PuzzleLevel(levelNumber: 34, name: "Stone Arch", coinReward: 1840, lives: 6, rowsArt: [
            "############",
            "############",
            "###......###",
            "##........##",
            "#..........#",
            "#..........#",
            "#..........#",
            "#..........#",
            "#..........#",
            "#..........#",
            "#..........#",
            "#..........#",
        ]),
        PuzzleLevel(levelNumber: 35, name: "City Skyline", coinReward: 1900, lives: 6, rowsArt: [
            "##....#.......",
            "##....#.......",
            "##....#..##...",
            "##.##.#..##...",
            "##.##.#..##.##",
            "##.##.#..##.##",
            "##.##.##.##.##",
            "##.##.##.##.##",
            "##.##.##.##.##",
        ]),
    ]

    static func byNumber(_ number: Int) -> PuzzleLevel {
        all.first(where: { $0.levelNumber == number }) ?? all[0]
    }
}
