package com.bjhartin.helloworld

import cats.effect.{IO, Ref}
import cats.effect.testing.scalatest.AsyncIOSpec
import org.scalatest.freespec.AsyncFreeSpec
import org.scalatest.matchers.should.Matchers
import fs2.{Pipe, Stream}
import fs2.text

class MainSpec extends AsyncFreeSpec with AsyncIOSpec with Matchers {

  // Helper to create an output pipe that captures content to a Ref
  private def captureOutputPipe(ref: Ref[IO, String]): Pipe[IO, Byte, Nothing] = { stream =>
    stream
      .through(text.utf8.decode)
      .evalMap(s => ref.update(_ + s))
      .drain
  }

  // Test method that captures output and returns both exit code and captured output
  private def runWithCapture(args: List[String]): IO[(cats.effect.ExitCode, String)] = {
    for {
      outputRef <- IO.ref("")
      exitCode <- Main.runWithOutput(args, captureOutputPipe(outputRef))
      capturedOutput <- outputRef.get
    } yield (exitCode, capturedOutput)
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
    
    "should print correct quote for --quote-1 flag" in {
      runWithCapture(List("--quote-1")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The only way to do great work is to love what you do.\" - Steve Jobs"
      }
    }
    
    "should print correct quote for --quote-2 flag" in {
      runWithCapture(List("--quote-2")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"Innovation distinguishes between a leader and a follower.\" - Steve Jobs"
      }
    }
    
    "should print correct quote for --quote-3 flag" in {
      runWithCapture(List("--quote-3")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The future belongs to those who believe in the beauty of their dreams.\" - Eleanor Roosevelt"
      }
    }
    
    "should print correct quote for --quote-4 flag" in {
      runWithCapture(List("--quote-4")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"Success is not final, failure is not fatal: it is the courage to continue that counts.\" - Winston Churchill"
      }
    }
    
    "should print correct quote for --quote-5 flag" in {
      runWithCapture(List("--quote-5")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The only impossible journey is the one you never begin.\" - Tony Robbins"
      }
    }
    
    "should print correct quote for --quote-6 flag" in {
      runWithCapture(List("--quote-6")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"Life is what happens when you're busy making other plans.\" - John Lennon"
      }
    }
    
    "should print correct quote for --quote-7 flag" in {
      runWithCapture(List("--quote-7")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"The best time to plant a tree was 20 years ago. The second best time is now.\" - Chinese Proverb"
      }
    }
    
    "should print correct quote for --quote-8 flag" in {
      runWithCapture(List("--quote-8")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"Be yourself; everyone else is already taken.\" - Oscar Wilde"
      }
    }
    
    "should print correct quote for --quote-9 flag" in {
      runWithCapture(List("--quote-9")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"It is during our darkest moments that we must focus to see the light.\" - Aristotle"
      }
    }
    
    "should print correct quote for --quote-10 flag" in {
      runWithCapture(List("--quote-10")).asserting { case (exitCode, output) =>
        exitCode shouldBe cats.effect.ExitCode.Success
        output shouldBe "\"In the end, we will remember not the words of our enemies, but the silence of our friends.\" - Martin Luther King Jr."
      }
    }

    // Keep some of the old tests that just check exit codes for broader coverage
    "should handle --quote-1 flag" in {
      Main.run(List("--quote-1")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-2 flag" in {
      Main.run(List("--quote-2")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-3 flag" in {
      Main.run(List("--quote-3")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-4 flag" in {
      Main.run(List("--quote-4")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-5 flag" in {
      Main.run(List("--quote-5")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-6 flag" in {
      Main.run(List("--quote-6")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-7 flag" in {
      Main.run(List("--quote-7")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-8 flag" in {
      Main.run(List("--quote-8")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-9 flag" in {
      Main.run(List("--quote-9")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-10 flag" in {
      Main.run(List("--quote-10")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
  }
}