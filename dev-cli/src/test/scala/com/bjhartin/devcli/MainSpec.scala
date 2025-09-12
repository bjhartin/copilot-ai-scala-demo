package com.bjhartin.devcli

import cats.effect.testing.scalatest.AsyncIOSpec
import org.scalatest.freespec.AsyncFreeSpec
import org.scalatest.matchers.should.Matchers
import org.scalacheck.Gen
import org.scalatestplus.scalacheck.ScalaCheckPropertyChecks

class MainSpec extends AsyncFreeSpec with AsyncIOSpec with Matchers with ScalaCheckPropertyChecks {

  "DevCommand" - {
    "RunCmd should hold name properly" in {
      forAll(Gen.option(Gen.alphaNumStr)) { nameOpt =>
        val cmd = Main.RunCmd(nameOpt)
        cmd.name shouldBe nameOpt
      }
    }
  }
}