# develop
  # Feature: Added basic support for running Punchblock apps on Asterisk. Calls coming in to AsyncAGI result in the client receiving an Offer, hangup events are sent, and accept/answer/hangup commands work.

# v0.6.1
  * Feature: Allow instructing the connection we are ready. An XMPP connection will send initial presence with a status of 'chat' to the rayo domain
  * Bugfix: When running on Asterisk, two FullyBooted events will now trigger a connected event
  * Bugfix: No longer ignore offers from the specified rayo domain on XMPP connections
  * Feature: Tag all event objects with the XMPP domain they came from

# v0.6.0
  * API change: Punchblock consumers now need to instantiate both a Connection and a Client (see the punchblock-console gem for an example)
  * Feature: Added a Connection for Asterisk, utilising RubyAMI to open an AMI connection to Asterisk, and allowing AMI actions to be executed. AMI events are handled by the client event handler.
  * Deprecation: The punchblock-console and the associated DSL are now deprecated and the punchblock-console gem should be used instead

# v0.5.1
  API change: Connections now raise a Punchblock::Connection::Connected instance as an event, rather than the class itself

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
