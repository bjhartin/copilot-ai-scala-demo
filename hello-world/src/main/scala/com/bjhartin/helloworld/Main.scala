package com.bjhartin.helloworld

import cats.effect.{ExitCode, IO, IOApp}
import cats.syntax.all._
import fs2.{Stream, text}
import fs2.io.stdout

object Main extends IOApp {

  def run(args: List[String]): IO[ExitCode] = {
    val greeting = args.headOption.getOrElse("World")
    
    val helloStream = Stream
      .emit(s"Hello, $greeting!")
      .through(text.utf8.encode)
      .through(stdout[IO])
    
    helloStream.compile.drain.as(ExitCode.Success)
  }
}