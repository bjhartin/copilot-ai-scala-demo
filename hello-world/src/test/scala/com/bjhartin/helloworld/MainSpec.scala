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
    
    "should evaluate integer addition with --evaluate" in {
      Main.run(List("--evaluate", "3+3")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
    
    "should evaluate decimal addition with --evaluate" in {
      Main.run(List("--evaluate", "3+0.5")).asserting(_ shouldBe cats.effect.ExitCode.Success)
    }
  }
  
  "Evaluator" - {
    "should evaluate simple integer addition" in {
      Main.evaluateExpression("3+3") shouldBe Right("6")
    }
    
    "should evaluate decimal addition" in {
      Main.evaluateExpression("3+0.5") shouldBe Right("3.5")
    }
    
    "should handle invalid expressions" in {
      Main.evaluateExpression("invalid").isLeft shouldBe true
    }
  }
}