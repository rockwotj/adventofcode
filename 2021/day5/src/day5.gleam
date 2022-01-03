import gleam/io
import gleam/list
import gleam/string
import gleam/map
import gleam/int
import gleam/option
import gleam/erlang/file
import gleam/result

type Point {
  Point(x: Int, y: Int)
}

type LineAnchor {
  LineAnchor(start: Point, end: Point)
}

fn parse(line: String) -> Result(LineAnchor, Nil) {
  let parse_point = fn(str: String) -> Result(Point, Nil) {
    case string.split(str, ",") {
      [x_str, y_str] -> {
        try x = int.parse(x_str)
        try y = int.parse(y_str)
        Ok(Point(x, y))
      }
      _ -> Error(Nil)
    }
  }
  case string.split(line, " -> ") {
    [start_str, end_str] -> {
      try start = parse_point(start_str)
      try end = parse_point(end_str)
      Ok(LineAnchor(start, end))
    }
    _ -> Error(Nil)
  }
}

type LineSegment =
  List(Point)

fn expand_line_anchor(anchor: LineAnchor) -> Result(LineSegment, LineAnchor) {
  let range = fn(a: Int, b: Int) -> List(Int) {
    list.append(list.range(a, b), [b])
  }
  case anchor {
    LineAnchor(Point(start_x, start_y), Point(end_x, end_y)) if start_x == end_x ->
      range(start_y, end_y)
      |> list.map(Point(x: start_x, y: _))
      |> Ok
    LineAnchor(Point(start_x, start_y), Point(end_x, end_y)) if start_y == end_y ->
      range(start_x, end_x)
      |> list.map(Point(y: start_y, x: _))
      |> Ok
    LineAnchor(Point(start_x, start_y), Point(end_x, end_y)) -> {
      try zipped =
        list.strict_zip(range(start_x, end_x), range(start_y, end_y))
        |> result.replace_error(anchor)
      zipped
      |> list.map(fn(pair) {
        let #(x, y) = pair
        Point(x, y)
      })
      |> Ok
    }
  }
}

type HotspotGrid =
  map.Map(Point, Int)

fn compute_grid(segments: List(LineSegment)) -> HotspotGrid {
  let increment = fn(acc: HotspotGrid, p: Point) -> HotspotGrid {
    map.update(acc, p, fn(prev) { 1 + option.unwrap(prev, or: 0) })
  }
  segments
  |> list.flatten
  |> list.fold(map.new(), increment)
}

fn overlapping_points_count(grid: HotspotGrid) -> Int {
  grid
  |> map.values
  |> list.filter(fn(count) { count > 1 })
  |> list.length
}

pub fn main() {
  assert Ok(contents) = file.read("input.txt")
  assert Ok(lines) =
    contents
    |> string.split("\n")
    |> list.try_map(parse)
  assert Ok(expanded) =
    lines
    |> list.try_map(expand_line_anchor)
  let count =
    expanded
    |> compute_grid
    |> overlapping_points_count
  io.print("Number of overlapping points: ")
  io.println(int.to_string(count))
}
