package com.bjhartin.helloworld

import cats.effect.{ExitCode, IO, IOApp}
import cats.syntax.all._
import fs2.{Stream, text}
import fs2.io.stdout

object Main extends IOApp {

  def run(args: List[String]): IO[ExitCode] = {
    args.headOption match {
      case Some("--about") =>
        val aboutStream = Stream
          .emit("This application exists as part of a repository which is a demonstration of how to use copilot agent in the cloud.")
          .through(text.utf8.encode)
          .through(stdout[IO])
        aboutStream.compile.drain.as(ExitCode.Success)
        
      case _ =>
        val greeting = args.headOption.getOrElse("World")
        val helloStream = Stream
          .emit(s"Hello, $greeting!")
          .through(text.utf8.encode)
          .through(stdout[IO])
        helloStream.compile.drain.as(ExitCode.Success)
    }
  }
}