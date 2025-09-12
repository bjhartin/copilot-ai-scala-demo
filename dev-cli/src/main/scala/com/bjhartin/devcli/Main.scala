package com.bjhartin.devcli

import cats.effect.{ExitCode, IO, IOApp}
import cats.syntax.all._
import com.monovore.decline._
import java.nio.file.Paths

object Main extends IOApp {

  sealed trait DevCommand
  case class RunCmd(name: Option[String]) extends DevCommand
  case object BuildCmd extends DevCommand
  case object TestCmd extends DevCommand

  private val runCommand: Opts[DevCommand] = 
    Opts.argument[String]("name").orNone.map(RunCmd.apply)

  private val buildCommand: Opts[DevCommand] = 
    Opts.unit.as(BuildCmd)

  private val testCommand: Opts[DevCommand] = 
    Opts.unit.as(TestCmd)

  private val commands = Opts.subcommands(
    Command("run", "Run the hello-world application")(runCommand),
    Command("build", "Build all subprojects")(buildCommand), 
    Command("test", "Run all tests")(testCommand)
  )

  private val program = Command("dev-cli", "Development CLI for copilot-ai-demo")(commands)

  def run(args: List[String]): IO[ExitCode] = {
    program.parse(args) match {
      case Right(cmd) => executeCommand(cmd)
      case Left(help) => 
        IO.println(help.toString) *> IO.pure(ExitCode.Error)
    }
  }

  private def executeCommand(cmd: DevCommand): IO[ExitCode] = cmd match {
    case RunCmd(nameOpt) =>
      nameOpt match {
        case Some(name) => runSbtCommand(s"'helloWorld/run $name'")
        case None => runSbtCommand("helloWorld/run")
      }
      
    case BuildCmd =>
      runSbtCommand("compile")
      
    case TestCmd =>
      runSbtCommand("test")
  }

  private def runSbtCommand(command: String): IO[ExitCode] = {
    val sbtPath = Paths.get(System.getProperty("user.dir"), "sbt", "bin", "sbt")
    
    IO.println(s"Executing: sbt $command") *>
      IO.blocking {
        import scala.sys.process._
        val exitCode = s"$sbtPath $command".!
        if (exitCode == 0) ExitCode.Success else ExitCode.Error
      }
  }
}