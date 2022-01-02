import gleam/io
import gleam/erlang/file
import gleam/string
import gleam/list
import gleam/result
import gleam/int

type State {
  Init
  Measurement(previous: Int, increases: Int)
}

fn calculate_next_state(state: State, depth: Int) -> State {
  let new_count = case state {
    Init -> 0
    Measurement(prev, count) if depth > prev -> count + 1
    Measurement(_, count) -> count
  }
  Measurement(depth, new_count)
}

pub fn main() {
  assert Ok(contents) = file.read("input.txt")
  assert Ok(depths) = contents 
  |> string.trim
  |> string.split(on: "\n")
  |> list.map(with: int.parse)
  |> result.all
  let result = depths |> list.fold(from: Init, with: calculate_next_state)
  io.print("Number of times the depth increased: ")
  io.println(int.to_string(case result {
    Init -> 0
    Measurement(_, count) -> count
  }))
}
