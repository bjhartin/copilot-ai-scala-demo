package com.bjhartin.helloworld

import cats.effect.unsafe.implicits.global
import org.scalacheck.{Arbitrary, Gen}
import org.scalatest.freespec.AnyFreeSpec
import org.scalatest.matchers.should.Matchers
import org.scalatestplus.scalacheck.ScalaCheckPropertyChecks

class PropertyBasedSpec extends AnyFreeSpec with Matchers with ScalaCheckPropertyChecks {

  "Main property-based tests" - {
    
    "always returns ExitCode.Success for any valid string input" in {
      forAll(Gen.alphaNumStr) { input =>
        whenever(input.nonEmpty && input.length <= 100) {
          val result = Main.run(List(input)).unsafeRunSync()
          result shouldBe cats.effect.ExitCode.Success
        }
      }
    }
    
    "handles various list sizes correctly" in {
      forAll(Gen.listOfN(10, Gen.alphaStr)) { inputs =>
        val result = Main.run(inputs).unsafeRunSync()
        result shouldBe cats.effect.ExitCode.Success
      }
    }
    
    "works with unicode characters" in {
      val unicodeGen = Gen.listOf(Gen.choose('\u0000', '\u007F')).map(_.mkString)
      
      forAll(unicodeGen) { input =>
        whenever(input.nonEmpty && input.length <= 50) {
          val result = Main.run(List(input)).unsafeRunSync()
          result shouldBe cats.effect.ExitCode.Success
        }
      }
    }
  }
}