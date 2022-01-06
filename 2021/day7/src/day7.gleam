import gleam/io
import gleam/list
import gleam/int
import gleam/string
import gleam/erlang/file

type Position = Int

fn parse(line: String) -> List(Position) {
  assert Ok(result) = line |> string.split(",") |> list.try_map(int.parse)
  result
}

fn min(a: List(Int)) -> Int {
  assert Ok(m) = list.reduce(a, int.min)
  m
}

fn max(a: List(Int)) -> Int {
  assert Ok(m) = list.reduce(a, int.max)
  m
}

fn fuel_to_move_all_to(target: Position, crabs: List(Position)) -> Int {
  list.fold(crabs, 0, fn(acc, pos) {
    let distance = int.absolute_value(pos - target)
    // The cost is the nth triangle number
    acc + { { distance * { distance + 1 } } / 2 }
  })
}

pub fn main() {
  assert Ok(contents) = file.read("input.txt")
  let positions = parse(contents)
  let minimum = min(positions)
  let maximum = max(positions)
  let [smallest, ..] = list.range(from: minimum, to: maximum + 1)
    |> list.map(fuel_to_move_all_to(_, positions))
    |> list.sort(int.compare)
  io.print("Smallest fuel: ")
  io.println(int.to_string(smallest))
}
