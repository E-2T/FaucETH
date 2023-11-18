import {
  EventCreated as EventCreatedEvent,
  EventVisibilityChanged as EventVisibilityChangedEvent
} from "../generated/Container/Container"
import { EventCreated, EventVisibilityChanged } from "../generated/schema"

export function handleEventCreated(event: EventCreatedEvent): void {
  let entity = new EventCreated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.name = event.params.name
  entity.owner = event.params.owner
  entity.whitelist = event.params.whitelist
  entity.withdrawLimit = event.params.withdrawLimit

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleEventVisibilityChanged(
  event: EventVisibilityChangedEvent
): void {
  let entity = new EventVisibilityChanged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.name = event.params.name
  entity.value = event.params.value

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
