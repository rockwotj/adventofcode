import gleam/io
import gleam/erlang/file
import gleam/list
import gleam/string
import gleam/result
import gleam/int

type Command {
  Forward(dx: Int)
  Down(dy: Int)
  Up(dy: Int)
}

type Position {
  Position(x: Int, y: Int)
}

fn initial_position() -> Position {
  Position(x: 0, y: 0)
}

fn move(pos: Position, cmd: Command) -> Position {
  case cmd {
    Forward(dx) -> Position(x: pos.x + dx, y: pos.y)
    Down(dy) -> Position(x: pos.x, y: pos.y + dy)
    Up(dy) -> Position(x: pos.x, y: pos.y - dy)
  }
}

fn parse_commands(lines: List(String)) -> Result(List(Command), String) {
  lines
    |> list.map(with: fn(line) {
        let [cmd, delta_str] = line |> string.split(on: " ")
        try delta = int.parse(delta_str)
          |> result.replace_error(string.concat(["Invalid number: ", delta_str]))
        case cmd {
          "forward" -> Ok(Forward(delta))
          "down" -> Ok(Down(delta))
          "up" -> Ok(Up(delta))
          _ -> Error(string.concat(["Unknown command: ", cmd]))
        }
      })
    |> result.all
}

pub fn main() {
  assert Ok(contents) = file.read("input.txt")
  assert Ok(cmds) = contents
    |> string.trim
    |> string.split(on: "\n")
    |> parse_commands
  let final_position = list.fold(cmds, from: initial_position(), with: move)
  io.print("Final position ")
  io.println(string.concat(["x: ", int.to_string(final_position.x), " y: ", int.to_string(final_position.y)]))
  io.print("Final position product: ")
  io.println(int.to_string(final_position.x * final_position.y))
}
