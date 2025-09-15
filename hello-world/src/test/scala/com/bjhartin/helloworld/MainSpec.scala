package com.bjhartin.helloworld

import cats.effect.IO
import cats.effect.testing.scalatest.AsyncIOSpec
import org.scalatest.freespec.AsyncFreeSpec
import org.scalatest.matchers.should.Matchers

class MainSpec extends AsyncFreeSpec with AsyncIOSpec with Matchers {

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
    
    "should handle --quote-1 flag" in {
      Main.run(List("--quote-1")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should handle --quote-2 flag" in {
      Main.run(List("--quote-2")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
  }
}