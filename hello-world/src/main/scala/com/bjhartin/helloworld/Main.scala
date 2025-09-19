package com.bjhartin.helloworld

import cats.effect.{ExitCode, IO, IOApp}
import cats.syntax.all._
import fs2.{Stream, text}
import fs2.io.stdout

object Main extends IOApp {
  // Main application entry point for hello-world with arithmetic evaluation support
  def run(args: List[String]): IO[ExitCode] = {
    args match {
      case "--evaluate" :: expression :: _ =>
        evaluateExpression(expression) match {
          case Right(result) =>
            val resultStream = Stream
              .emit(result)
              .through(text.utf8.encode)
              .through(stdout[IO])
            resultStream.compile.drain.as(ExitCode.Success)
          case Left(_) =>
            IO.pure(ExitCode.Error)
        }
      case "--evaluate" :: Nil =>
        IO.pure(ExitCode.Error)
      case _ =>
        val greeting = args.headOption.getOrElse("World")
        val helloStream = Stream
          .emit(s"Hello, $greeting!")
          .through(text.utf8.encode)
          .through(stdout[IO])
        helloStream.compile.drain.as(ExitCode.Success)
    }
  }
  
  // Evaluates arithmetic expressions containing addition operator
  def evaluateExpression(expression: String): Either[String, String] = {
    if (expression.contains("+")) {
      val parts = expression.split("\\+")
      if (parts.length == 2) {
        val left = parts(0).trim
        val right = parts(1).trim
        
        (parseNumber(left), parseNumber(right)) match {
          case (Some(leftNum), Some(rightNum)) =>
            val result = leftNum + rightNum
            // Format result to avoid unnecessary decimals
            if (result == result.toLong.toDouble) {
              Right(result.toLong.toString)
            } else {
              Right(result.toString)
            }
          case _ => Left("Invalid numbers in expression")
        }
      } else {
        Left("Invalid expression format")
      }
    } else {
      Left("Expression must contain addition operator")
    }
  }
  
  private def parseNumber(str: String): Option[Double] = {
    try {
      Some(str.toDouble)
    } catch {
      case _: NumberFormatException => None
    }
  }
}