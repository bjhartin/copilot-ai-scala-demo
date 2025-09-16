package com.bjhartin.helloworld

import cats.effect.IO
import cats.effect.testing.scalatest.AsyncIOSpec
import org.scalatest.freespec.AsyncFreeSpec
import org.scalatest.matchers.should.Matchers
import java.io.{ByteArrayOutputStream, PrintStream}

class MainSpec extends AsyncFreeSpec with AsyncIOSpec with Matchers {

  // Helper to capture System.out directly since FS2 stdout bypasses Console.withOut
  // Synchronized to handle concurrent test execution
  private def captureSystemOut[A](action: IO[A]): IO[(A, String)] = {
    IO {
      synchronized {
        val outputStream = new ByteArrayOutputStream()
        val printStream = new PrintStream(outputStream)
        val originalOut = System.out
        
        try {
          System.setOut(printStream)
          val result = action.unsafeRunSync()
          val output = outputStream.toString("UTF-8")
          (result, output)
        } finally {
          System.setOut(originalOut)
        }
      }
    }
  }

  "Main" - {
    "should return ExitCode.Success for any input" in {
      Main.run(List("TestName")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle empty arguments" in {
      Main.run(List.empty).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle multiple arguments (taking the first)" in {
      Main.run(List("first", "second")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --about flag" in {
      Main.run(List("--about")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --help flag" in {
      Main.run(List("--help")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should print correct content for --about flag" in {
      captureSystemOut(Main.run(List("--about"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "This application exists as part of a repository which is a demonstration of how to use copilot agent in the cloud."
      }
    }
    
    "should print correct content for --help flag" in {
      captureSystemOut(Main.run(List("--help"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        val expectedHelp = """Usage: sbt "helloWorld/run [OPTION|NAME]"
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
            |  --quote-9      Display yet another inspiring famous quote
            |  --quote-10     Display yet another inspiring famous quote
            |  --quote-11     Display yet another inspiring famous quote
            |  --quote-12     Display yet another inspiring famous quote
            |  --quote-70ddd078-fc28-4f54-933a-0a57c5d7169c Display yet another inspiring famous quote
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
            |  sbt "helloWorld/run --quote-9" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-10" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-11" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-12" # Display yet another famous quote
            |  sbt "helloWorld/run --quote-70ddd078-fc28-4f54-933a-0a57c5d7169c" # Display yet another famous quote
            |""".stripMargin
        output shouldBe expectedHelp
      }
    }
    
    "should print correct quote for --quote-1 flag" in {
      captureSystemOut(Main.run(List("--quote-1"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The only way to do great work is to love what you do.\" - Steve Jobs"
      }
    }
    
    "should print correct quote for --quote-2 flag" in {
      captureSystemOut(Main.run(List("--quote-2"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"Innovation distinguishes between a leader and a follower.\" - Steve Jobs"
      }
    }
    
    "should print correct quote for --quote-3 flag" in {
      captureSystemOut(Main.run(List("--quote-3"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The future belongs to those who believe in the beauty of their dreams.\" - Eleanor Roosevelt"
      }
    }
    
    "should print correct quote for --quote-4 flag" in {
      captureSystemOut(Main.run(List("--quote-4"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"Success is not final, failure is not fatal: it is the courage to continue that counts.\" - Winston Churchill"
      }
    }
    
    "should print correct quote for --quote-5 flag" in {
      captureSystemOut(Main.run(List("--quote-5"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The only impossible journey is the one you never begin.\" - Tony Robbins"
      }
    }
    
    "should print correct quote for --quote-6 flag" in {
      captureSystemOut(Main.run(List("--quote-6"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"Life is what happens when you're busy making other plans.\" - John Lennon"
      }
    }
    
    "should print correct quote for --quote-7 flag" in {
      captureSystemOut(Main.run(List("--quote-7"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The best time to plant a tree was 20 years ago. The second best time is now.\" - Chinese Proverb"
      }
    }
    
    "should print correct quote for --quote-8 flag" in {
      captureSystemOut(Main.run(List("--quote-8"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"Be yourself; everyone else is already taken.\" - Oscar Wilde"
      }
    }
    
    "should print correct quote for --quote-9 flag" in {
      captureSystemOut(Main.run(List("--quote-9"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"It is during our darkest moments that we must focus to see the light.\" - Aristotle"
      }
    }
    
    "should print correct quote for --quote-10 flag" in {
      captureSystemOut(Main.run(List("--quote-10"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"In the end, we will remember not the words of our enemies, but the silence of our friends.\" - Martin Luther King Jr."
      }
    }
    
    "should print correct quote for --quote-11 flag" in {
      captureSystemOut(Main.run(List("--quote-11"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The way to get started is to quit talking and begin doing.\" - Walt Disney"
      }
    }
    
    "should print correct quote for --quote-12 flag" in {
      captureSystemOut(Main.run(List("--quote-12"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The future belongs to those who believe in the beauty of their dreams.\" - Eleanor Roosevelt"
      }
    }
    
    "should print correct quote for --quote-70ddd078-fc28-4f54-933a-0a57c5d7169c flag" in {
      captureSystemOut(Main.run(List("--quote-70ddd078-fc28-4f54-933a-0a57c5d7169c"))).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"In the middle of difficulty lies opportunity.\" - Albert Einstein"
      }
    }
  }
}