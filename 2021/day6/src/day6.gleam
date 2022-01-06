import gleam/io
import gleam/erlang/file
import gleam/string
import gleam/iterator
import gleam/list
import gleam/int
import gleam/map
import gleam/option
import gleam/result
import gleam/otp/task

type Age = Int
type Generation = map.Map(Age, Int)
type FishGroup = #(Age, Int)

fn advance_group(group: FishGroup) -> Generation {
  case group {
    #(0, size) -> [#(6, size), #(8, size)]
    #(age, size) -> [#(age - 1, size)]
  } |> map.from_list
}


fn combine_generations(a: Generation, b: Generation) -> Generation {
  let increment = fn(x, y) {
    case x {
      option.Some(i) -> i + y
      option.None -> y
    }
  }
  map.fold(b, a, fn(acc, age: Age, size: Int) {
    map.update(acc, age, increment(_, size))
  })
}

fn next_generation(gen: Generation, _: Int) -> Generation {
  gen
    |> map.to_list
    |> list.map(advance_group)
    |> list.reduce(combine_generations)
    |> result.unwrap(map.new())
}

fn run_simulation(gen: Generation) -> Int {
  list.range(from: 0, to: 256)
    |> list.fold(gen, next_generation)
    |> map.values
    |> int.sum
}

fn parse(line: String) -> Generation {
  assert Ok(days) = line
  |> string.split(",")
  |> list.try_map(int.parse)
  assert Ok(gen_a) = list.map(days, fn(age) { map.from_list([#(age, 1)]) }) |> list.reduce(combine_generations)
  gen_a
}

pub fn main() {
  assert Ok(contents) = file.read("input.txt")
  let num_fish = parse(contents) |> run_simulation
  io.print("Number of fish after 256 days: ")
  io.println(int.to_string(num_fish))
}
