ThisBuild / organization := "com.bjhartin"
ThisBuild / scalaVersion := "2.13.12"

ThisBuild / scalacOptions ++= Seq(
  "-deprecation",
  "-encoding", "UTF-8",
  "-language:higherKinds",
  "-language:postfixOps",
  "-feature",
  "-Xfatal-warnings"
)

val CatsVersion = "2.10.0"
val CatsEffectVersion = "3.5.2"
val Fs2Version = "3.9.3"
val ScalaCheckVersion = "1.17.0"

lazy val commonDependencies = Seq(
  "org.typelevel" %% "cats-core" % CatsVersion,
  "org.typelevel" %% "cats-effect" % CatsEffectVersion,
  "co.fs2" %% "fs2-core" % Fs2Version,
  "co.fs2" %% "fs2-io" % Fs2Version,
  "org.scalacheck" %% "scalacheck" % ScalaCheckVersion % Test,
  "org.scalatest" %% "scalatest" % "3.2.17" % Test,
  "org.scalatestplus" %% "scalacheck-1-17" % "3.2.17.0" % Test,
  "org.typelevel" %% "cats-effect-testing-scalatest" % "1.5.0" % Test
)

lazy val root = (project in file("."))
  .aggregate(helloWorld, devCli)
  .settings(
    name := "copilot-ai-demo"
  )

lazy val helloWorld = (project in file("hello-world"))
  .settings(
    name := "hello-world",
    libraryDependencies ++= commonDependencies,
    Compile / mainClass := Some("com.bjhartin.helloworld.Main")
  )

lazy val devCli = (project in file("dev-cli"))
  .settings(
    name := "dev-cli",
    libraryDependencies ++= commonDependencies ++ Seq(
      "com.monovore" %% "decline" % "2.4.1"
    ),
    Compile / mainClass := Some("com.bjhartin.devcli.Main"),
    assembly / assemblyJarName := "dev-cli.jar"
  )
  .enablePlugins(AssemblyPlugin)

addCommandAlias("fmt", "all scalafmtSbt scalafmt test:scalafmt")
addCommandAlias("check", "all scalafmtSbtCheck scalafmtCheck test:scalafmtCheck")