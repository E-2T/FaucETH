import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  EventCreated,
  EventVisibilityChanged
} from "../generated/Container/Container"

export function createEventCreatedEvent(
  name: string,
  owner: Address,
  whitelist: Array<Address>,
  withdrawLimit: BigInt
): EventCreated {
  let eventCreatedEvent = changetype<EventCreated>(newMockEvent())

  eventCreatedEvent.parameters = new Array()

  eventCreatedEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  eventCreatedEvent.parameters.push(
    new ethereum.EventParam("owner", ethereum.Value.fromAddress(owner))
  )
  eventCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "whitelist",
      ethereum.Value.fromAddressArray(whitelist)
    )
  )
  eventCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "withdrawLimit",
      ethereum.Value.fromUnsignedBigInt(withdrawLimit)
    )
  )

  return eventCreatedEvent
}

export function createEventVisibilityChangedEvent(
  name: string,
  value: boolean
): EventVisibilityChanged {
  let eventVisibilityChangedEvent = changetype<EventVisibilityChanged>(
    newMockEvent()
  )

  eventVisibilityChangedEvent.parameters = new Array()

  eventVisibilityChangedEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  eventVisibilityChangedEvent.parameters.push(
    new ethereum.EventParam("value", ethereum.Value.fromBoolean(value))
  )

  return eventVisibilityChangedEvent
}
