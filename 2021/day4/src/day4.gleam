import gleam/io
import gleam/bool
import gleam/list
import gleam/set
import gleam/result
import gleam/function
import gleam/string
import gleam/int
import gleam/erlang/file

type ParseError {
  InvalidBingoRow(row: String)
  InvalidDrawnNumbers
  EmptyFile
}

type BingoGrid = List(List(Int))

fn parse_bingo_grid(grid_str: List(String)) -> Result(BingoGrid, ParseError) {
  let parse_bingo_row = fn(row: String) -> Result(List(Int), ParseError) {
    row
      |> string.split(on: " ")
      |> list.filter(fn(num) { num |> string.is_empty |> bool.negate })
      |> list.try_map(int.parse)
      |> result.replace_error(InvalidBingoRow(row))
  }
  // Drop the first empty line before every grid.
  grid_str |> list.drop(1) |> list.try_map(parse_bingo_row)
}

type DrawnNumbers = List(Int)

fn parse_drawn_numbers(input: String) -> Result(DrawnNumbers, ParseError) {
  input |> string.split(on: ",") |> list.try_map(int.parse) |> result.replace_error(InvalidDrawnNumbers)
}

fn is_winner(grid: BingoGrid, drawn: DrawnNumbers) -> Bool {
  let row_is_winner = fn(row: List(Int)) -> Bool {
    row |> list.all(list.contains(drawn, _))
  }
  { grid |> list.any(row_is_winner) } || { grid |> list.transpose |> list.any(row_is_winner) }
}

type Puzzle {
  Puzzle(drawn: DrawnNumbers, grids: List(BingoGrid))
}

fn parse_puzzle(input: String) -> Result(Puzzle, ParseError) {
  let lines = input |> string.split(on: "\n")
  case lines {
    [head, ..tail] -> {
      try drawn = parse_drawn_numbers(head)
      try grids = tail |> list.sized_chunk(into: 6) |> list.try_map(parse_bingo_grid)
      Ok(Puzzle(drawn, grids))
    }
    _ -> Error(EmptyFile)
  }
}

type PuzzleSolution {
  PuzzleSolution(grid: BingoGrid, drawn: DrawnNumbers)
}

type FindState {
  Looking(drawn_so_far: DrawnNumbers)
  Found(solution: PuzzleSolution)
}

fn find_first_winner(puzzle: Puzzle) -> PuzzleSolution {
  let find_winner = fn(state: FindState, drawn: Int) -> list.ContinueOrStop(FindState) {
    assert Looking(prev_drawn) = state
    let drawn_so_far = [drawn, ..prev_drawn]
    case puzzle.grids |> list.find(is_winner(_, drawn_so_far)) {
      Ok(grid) -> list.Stop(Found(PuzzleSolution(grid, drawn_so_far)))
      _ -> list.Continue(Looking(drawn_so_far))
    }
  }
  assert Found(solution) = list.fold_until(puzzle.drawn, Looking(drawn_so_far: []), find_winner)
  solution
}

fn calculate_score(solution: PuzzleSolution) -> Int {
  let unmarked_sum = solution.grid
    |> list.flatten
    |> list.filter(function.compose(list.contains(solution.drawn, _), bool.negate))
    |> int.sum
  assert [last_drawn, ..] = solution.drawn
  unmarked_sum * last_drawn
}

pub fn main() {
  assert Ok(contents) = file.read("input.txt")
  assert Ok(puzzle) = parse_puzzle(contents)
  let score = find_first_winner(puzzle) |> calculate_score
  io.print("The first winning puzzle score is: ")
  io.println(int.to_string(score))
}
