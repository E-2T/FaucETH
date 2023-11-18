import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { EventCreated } from "../generated/schema"
import { EventCreated as EventCreatedEvent } from "../generated/Container/Container"
import { handleEventCreated } from "../src/container"
import { createEventCreatedEvent } from "./container-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let name = "Example string value"
    let owner = Address.fromString("0x0000000000000000000000000000000000000001")
    let whitelist = [
      Address.fromString("0x0000000000000000000000000000000000000001")
    ]
    let withdrawLimit = BigInt.fromI32(234)
    let newEventCreatedEvent = createEventCreatedEvent(
      name,
      owner,
      whitelist,
      withdrawLimit
    )
    handleEventCreated(newEventCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("EventCreated created and stored", () => {
    assert.entityCount("EventCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "EventCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "name",
      "Example string value"
    )
    assert.fieldEquals(
      "EventCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "owner",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "EventCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "whitelist",
      "[0x0000000000000000000000000000000000000001]"
    )
    assert.fieldEquals(
      "EventCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "withdrawLimit",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
