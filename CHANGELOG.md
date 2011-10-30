# develop

# v0.5.0
  * Refactoring/API change: Client and connection level concerns are now separated, and one must create a Connection to be passed to a Client on creation. Client now has the choice between an event queue and guarded event handlers.

# v0.4.3
  * Feature: Support for meta-data on recordings (size & duration)
  * Feature: Allow specifying all of Blather's setup options (required to use PB as an XMPP component)
  * Bugfix: Rayo events are discarded if they don't come from the specified domain
  * Bugfix: Component execution in the sample DSL now doesn't expect events on the main queue

# v0.4.2
  * Bugfix: Conference complete event was not being handled

# v0.4.1
  * Feature/API change: Components no longer have an event queue, but instead it is possible to define guarded event handlers via #register_event_handler

# v0.4.0
  * First public release
