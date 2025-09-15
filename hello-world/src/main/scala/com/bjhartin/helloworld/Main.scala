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
        
      case Some("--help") =>
        val helpText = 
          """Usage: sbt "helloWorld/run [OPTION|NAME]"
            |
            |A simple hello world application with command-line options.
            |
            |Arguments:
            |  NAME           Print "Hello, NAME!"
            |
            |Options:
            |  --about        Show information about this repository
            |  --help         Show this help message
            |  --quote-1      Display an inspiring famous quote
            |  --quote-2      Display another inspiring famous quote
            |  --quote-3      Display yet another inspiring famous quote
            |  --quote-4      Display yet another inspiring famous quote
            |  --quote-5      Display yet another inspiring famous quote
            |  --quote-6      Display yet another inspiring famous quote
            |  --quote-7      Display yet another inspiring famous quote
            |  --quote-8      Display yet another inspiring famous quote
            |
            |Examples:
            |  sbt "helloWorld/run"           # Output: Hello, World!
            |  sbt "helloWorld/run Alice"     # Output: Hello, Alice!
            |  sbt "helloWorld/run --about"   # Show repository information
            |  sbt "helloWorld/run --help"    # Show this help message
            |  sbt "helloWorld/run --quote-1" # Display a famous quote
            |  sbt "helloWorld/run --quote-2" # Display another famous quote
            |  sbt "helloWorld/run --quote-3" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-4" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-5" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-6" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-7" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-8" # Display yet another famous quote
            |""".stripMargin
        val helpStream = Stream
          .emit(helpText)
          .through(text.utf8.encode)
          .through(stdout[IO])
        helpStream.compile.drain.as(ExitCode.Success)
        
      case Some("--quote-1") =>
        val quoteStream = Stream
          .emit("\"The only way to do great work is to love what you do.\" - Steve Jobs")
          .through(text.utf8.encode)
          .through(stdout[IO])
        quoteStream.compile.drain.as(ExitCode.Success)
        
      case Some("--quote-2") =>
        val quoteStream = Stream
          .emit("\"Innovation distinguishes between a leader and a follower.\" - Steve Jobs")
          .through(text.utf8.encode)
          .through(stdout[IO])
        quoteStream.compile.drain.as(ExitCode.Success)
        
      case Some("--quote-3") =>
        val quoteStream = Stream
          .emit("\"The future belongs to those who believe in the beauty of their dreams.\" - Eleanor Roosevelt")
          .through(text.utf8.encode)
          .through(stdout[IO])
        quoteStream.compile.drain.as(ExitCode.Success)
        
      case Some("--quote-4") =>
        val quoteStream = Stream
          .emit("\"Success is not final, failure is not fatal: it is the courage to continue that counts.\" - Winston Churchill")
          .through(text.utf8.encode)
          .through(stdout[IO])
        quoteStream.compile.drain.as(ExitCode.Success)
        
      case Some("--quote-5") =>
        val quoteStream = Stream
          .emit("\"The only impossible journey is the one you never begin.\" - Tony Robbins")
          .through(text.utf8.encode)
          .through(stdout[IO])
        quoteStream.compile.drain.as(ExitCode.Success)
        
      case Some("--quote-6") =>
        val quoteStream = Stream
          .emit("\"Life is what happens when you're busy making other plans.\" - John Lennon")
          .through(text.utf8.encode)
          .through(stdout[IO])
        quoteStream.compile.drain.as(ExitCode.Success)
        
      case Some("--quote-7") =>
        val quoteStream = Stream
          .emit("\"The best time to plant a tree was 20 years ago. The second best time is now.\" - Chinese Proverb")
          .through(text.utf8.encode)
          .through(stdout[IO])
        quoteStream.compile.drain.as(ExitCode.Success)
        
      case Some("--quote-8") =>
        val quoteStream = Stream
          .emit("\"Be yourself; everyone else is already taken.\" - Oscar Wilde")
          .through(text.utf8.encode)
          .through(stdout[IO])
        quoteStream.compile.drain.as(ExitCode.Success)
        
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