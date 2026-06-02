import SwiftUI

/// State of a single grid cell as edited by the player.
enum CellMark {
    case empty
    case brick
    case cross
}

/// Two editing modes the player toggles between.
enum EditMode {
    case lay
    case mark
}

/// Overall round status, drives the SwiftUI overlays.
enum BlueprintStatus {
    case building
    case paused
    case complete
    case scrapped
}

/// Result of a single tap, lets the UI play the matching sound/haptic.
enum TapResult {
    case ignored
    case placed
    case removed
    case marked
    case mistake
    case scrappedRound
    case completedRound
}

/// Pure logic for a Blueprint (nonogram) round, ported from the Dart
/// `NonogramController`. Published so SwiftUI views repaint on change.
final class NonogramController: ObservableObject {
    let level: PuzzleLevel

    @Published private(set) var grid: [[CellMark]]
    @Published private(set) var mode: EditMode = .lay
    @Published private(set) var mistakes = 0
    @Published private(set) var bricksLaid = 0
    @Published private(set) var hintsUsed = 0
    @Published private(set) var status: BlueprintStatus = .building

    /// The last cell that triggered a wrong placement (for a brief flash).
    @Published private(set) var flashRow: Int?
    @Published private(set) var flashCol: Int?

    init(level: PuzzleLevel) {
        self.level = level
        self.grid = Array(
            repeating: Array(repeating: CellMark.empty, count: level.colCount),
            count: level.rowCount
        )
    }

    var rows: Int { level.rowCount }
    var cols: Int { level.colCount }
    var livesLeft: Int { max(0, min(level.lives, level.lives - mistakes)) }
    var maxLives: Int { level.lives }
    var bricksTotal: Int { level.brickCount }
    var isInteractive: Bool { status == .building }

    func cellAt(_ r: Int, _ c: Int) -> CellMark { grid[r][c] }

    func setMode(_ newMode: EditMode) {
        guard mode != newMode else { return }
        mode = newMode
    }

    func pause() {
        guard status == .building else { return }
        status = .paused
    }

    func resume() {
        guard status == .paused else { return }
        status = .building
    }

    @discardableResult
    func handleTap(_ r: Int, _ c: Int) -> TapResult {
        guard isInteractive else { return .ignored }
        flashRow = nil
        flashCol = nil

        let cell = grid[r][c]
        let shouldBeBrick = level.solutionAt(r, c)

        if mode == .lay {
            if cell == .brick {
                grid[r][c] = .empty
                bricksLaid -= 1
                return .removed
            }
            if cell == .cross {
                return .ignored
            }
            if shouldBeBrick {
                grid[r][c] = .brick
                bricksLaid += 1
                let won = checkComplete()
                return won ? .completedRound : .placed
            } else {
                mistakes += 1
                grid[r][c] = .cross
                flashRow = r
                flashCol = c
                if mistakes >= level.lives {
                    status = .scrapped
                    return .scrappedRound
                }
                return .mistake
            }
        } else {
            if cell == .brick { return .ignored }
            grid[r][c] = (cell == .cross) ? .empty : .cross
            return .marked
        }
    }

    @discardableResult
    func dragPaint(_ r: Int, _ c: Int) -> TapResult {
        guard isInteractive else { return .ignored }
        let cell = grid[r][c]
        guard cell == .empty else { return .ignored }

        if mode == .lay {
            if level.solutionAt(r, c) {
                grid[r][c] = .brick
                bricksLaid += 1
                let won = checkComplete()
                return won ? .completedRound : .placed
            }
            mistakes += 1
            grid[r][c] = .cross
            flashRow = r
            flashCol = c
            if mistakes >= level.lives {
                status = .scrapped
                return .scrappedRound
            }
            return .mistake
        } else {
            grid[r][c] = .cross
            return .marked
        }
    }

    func rowSatisfied(_ r: Int) -> Bool {
        for c in 0..<cols where level.solutionAt(r, c) && grid[r][c] != .brick {
            return false
        }
        return true
    }

    func colSatisfied(_ c: Int) -> Bool {
        for r in 0..<rows where level.solutionAt(r, c) && grid[r][c] != .brick {
            return false
        }
        return true
    }

    /// Reveals one correct, not-yet-laid brick. Returns false if none remain.
    @discardableResult
    func useHint() -> Bool {
        guard isInteractive else { return false }
        for r in 0..<rows {
            for c in 0..<cols where level.solutionAt(r, c) && grid[r][c] != .brick {
                grid[r][c] = .brick
                bricksLaid += 1
                hintsUsed += 1
                if checkComplete() { status = .complete }
                return true
            }
        }
        return false
    }

    func reviveWithExtraLife() {
        guard status == .scrapped else { return }
        mistakes = max(0, min(level.lives, level.lives - 1))
        status = .building
    }

    /// Resets the round back to a blank grid (used by "Restart"/"Replay").
    func reset() {
        grid = Array(
            repeating: Array(repeating: CellMark.empty, count: level.colCount),
            count: level.rowCount
        )
        mode = .lay
        mistakes = 0
        bricksLaid = 0
        hintsUsed = 0
        status = .building
        flashRow = nil
        flashCol = nil
    }

    @discardableResult
    private func checkComplete() -> Bool {
        for r in 0..<rows {
            for c in 0..<cols where level.solutionAt(r, c) && grid[r][c] != .brick {
                return false
            }
        }
        status = .complete
        return true
    }
}
