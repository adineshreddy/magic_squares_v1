import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import worker

pub fn start(max_limit: Int, times: Int) {
  io.println(
    "Boss starting with max_limit: "
    <> int.to_string(max_limit)
    <> " times: "
    <> int.to_string(times),
  )
  let boss_subject = process.new_subject()

  let chunk_size = case max_limit < 100 {
    True -> max_limit
    False -> 100
  }
	io.println("Chunk size: " <> int.to_string(chunk_size))

  let full_chunks = max_limit / chunk_size
	io.println("Full chunks: " <> int.to_string(full_chunks))

  let ends =
    list.range(1, full_chunks)
    |> list.map(fn(i) { i * chunk_size })
    |> list.append([max_limit])
	
	io.println("Chunk ends: " )
	echo ends

  let total_workers =
    list.fold(ends, 0, fn(upper_limit, acc) {
      let begin = case upper_limit > chunk_size {
        True -> {
          let rem = upper_limit % chunk_size
          case rem > 0 {
            True -> upper_limit - rem + 1
            False -> upper_limit - chunk_size + 1
          }
        }
        False -> 1
      }
      io.println(
        "Starting workers from "
        <> int.to_string(begin)
        <> " to "
        <> int.to_string(upper_limit),
      )
      list.range(begin, upper_limit)
      |> list.each(fn(i) {
        worker.start(boss_subject, i, times)
        Nil
      })

      acc + upper_limit - begin + 1
    })
	io.println("Total workers: " <> int.to_string(total_workers))
  loop(boss_subject, total_workers, 0)
}

fn loop(boss_subject: process.Subject(worker.Msg), remaining: Int, answers: Int) {
  case remaining {
    0 ->
      io.println(
        "All workers finished. Total answers: " <> int.to_string(answers),
      )
    _ ->
      case process.receive(boss_subject, within: 50_000) {
        Ok(msg) ->
          case msg {
            worker.Answer(index) -> {
              io.println("Answer: " <> int.to_string(index))
              loop(boss_subject, remaining, answers + 1)
            }

            worker.Done -> loop(boss_subject, remaining - 1, answers)
          }

        Error(_) -> io.println("Timeout waiting for messages")
      }
  }
}
