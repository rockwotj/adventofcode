import gleam/io
import gleam/list
import gleam/int
import gleam/string
import gleam/map
import gleam/option
import gleam/pair
import gleam/erlang/file
import gleam/result
import gleam/bitwise

type BitCount {
  BitCount(zeros: Int, ones: Int)
}

fn count_bits(bits: List(Int)) -> Result(List(BitCount), String) {
  let bit_to_count = fn(b: Int) -> Result(BitCount, String) {
    case b {
      0 -> Ok(BitCount(zeros: 1, ones: 0))
      1 -> Ok(BitCount(zeros: 0, ones: 1))
      _ -> Error(string.append("Invalid: ", int.to_string(b)))
    }
  }
  bits |> list.try_map(with: bit_to_count)
}

fn parse_bits(str: String) -> Result(List(Int), String) {
  let bit_to_count = fn(str: String) -> Result(Int, String) {
    case str {
      "0" -> Ok(0)
      "1" -> Ok(1)
      _ -> Error(string.append("Invalid: ", str))
    }
  }
  str |> string.to_graphemes |> list.try_map(with: bit_to_count)
}

fn sum_bit_count(a: BitCount, b: BitCount) -> BitCount {
  BitCount(zeros: a.zeros + b.zeros, ones: b.ones + a.ones)
}

fn most_common_bit(count: BitCount) -> Result(Int, String) {
  case count {
    BitCount(zeros, ones) if zeros > ones -> Ok(0)
    BitCount(zeros, ones) if zeros < ones -> Ok(1)
    _ -> Error("Equal number of bits!")
  }
}

fn least_common_bit(count: BitCount) -> Result(Int, String) {
  most_common_bit(count) |> result.then(fn (bit) {
    case bit {
      0 -> Ok(1)
      1 -> Ok(0)
      _ -> Error("What bit is this?")
    }
  })
}

type BitCountByIndex = map.Map(Int, BitCount)

fn sum(counts: List(List(BitCount))) -> BitCountByIndex {
  counts
    |> list.fold(map.new(), fn(acc, bits) {
        list.index_fold(bits, acc, fn(acc, bit, idx) {
          map.update(acc, idx, fn(value) {
            value
              |> option.map(sum_bit_count(_, bit))
              |> option.unwrap(bit)
          })
        })
    })
}

fn to_int(bits: List(Int)) -> Int {
  list.fold(bits, from: 0, with: fn (acc, val) {
    bitwise.shift_left(acc, 1) + val
  })
}

fn calc_rate(index: BitCountByIndex, selector: fn (BitCount) -> Result(Int, String)) -> Result(Int, String) {
  try selected_bits = index
    |> map.to_list
    |> list.try_map(fn (entry) {
      let #(k, v) = entry
      try selected = selector(v)
      Ok(#(k, selected))
    })
  selected_bits
    |> list.sort(by: fn(a, b) { int.compare(pair.first(a), pair.first(b)) })
    |> list.map(pair.second)
    |> to_int
    |> Ok
}

fn find_num_rate(
  values: List(List(Int)),
  index: BitCountByIndex,
  selector: fn (BitCount) -> Result(Int, String),
  position: Int,
  fallback: Int,
) -> Result(Int, String) {
  case values {
    [x] -> Ok(to_int(x))
    _ -> {
      try counts = map.get(index, position)
        |> result.replace_error(string.concat([
              "Bad position: ", 
              int.to_string(position),
              " ",
              int.to_string(map.size(index)),
        ]))
      let bit = selector(counts) |> result.unwrap(fallback)
      let filtered = list.filter(values, for: fn (bits) { list.at(bits, position) == Ok(bit) })
      try new_counts = list.try_map(filtered, count_bits)
      find_num_rate(filtered, sum(new_counts), selector, position + 1, fallback)
    }
  }
}

pub fn main() {
  assert Ok(contents) = file.read("input.txt")
  assert Ok(values) = contents
    |> string.trim
    |> string.split(on: "\n")
    |> list.try_map(parse_bits)
  assert Ok(counts) = list.try_map(values, count_bits)
  let indexed = sum(counts)
  assert Ok(gamma_rate) = calc_rate(indexed, most_common_bit)
  assert Ok(epsilon_rate) = calc_rate(indexed, least_common_bit)
  io.print("The power consumption is: ")
  io.println(int.to_string(gamma_rate * epsilon_rate))
  assert Ok(oxygen_gen_rating) = find_num_rate(values, indexed, most_common_bit, 0, 1)
  assert Ok(co2_scrubber_rating) = find_num_rate(values, indexed, least_common_bit, 0, 0)
  io.print("The oxygen_gen_rating is: ")
  io.println(int.to_string(oxygen_gen_rating))
  io.print("The co2 scrubber rating is: ")
  io.println(int.to_string(co2_scrubber_rating))
  io.print("The life support is: ")
  io.println(int.to_string(oxygen_gen_rating * co2_scrubber_rating))
}
