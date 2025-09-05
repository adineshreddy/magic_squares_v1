import gleam/io
import gleam/erlang/process
import gleam/list
import gleam/int

/// messages workers can send back
pub type Msg {
  Answer(Int)
  Done
}

/// start a worker that will send messages to the boss
pub fn start(boss: process.Subject(Msg), index: Int, times: Int) -> process.Pid {
  process.spawn(fn() {
    run(boss, index, times)
  })
}

fn run(boss: process.Subject(Msg), index: Int, times: Int) {
  let sum_of_squares =
    list.range(index, index + times - 1)
    |> list.map(fn(x) { x * x })
    |> list.fold(0, fn(a, b) { a + b })
	io.println("Worker " <> int.to_string(index) <> " sum_of_squares: " <> int.to_string(sum_of_squares))
  case is_perfect_square(sum_of_squares) {
    True -> process.send(boss, Answer(index))
    False -> Nil
  }

  process.send(boss, Done)
}

fn is_perfect_square(n: Int) -> Bool {
  case n {
    _ if n < 0 -> False
    0 -> True
    _ -> square_test(n, 1)
  }
}

fn square_test(remaining: Int, odd: Int) -> Bool {
  case remaining {
    0 -> True
    r if r < 0 -> False
    r -> square_test(r - odd, odd + 2)
  }
}