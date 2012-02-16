# develop
  * Feature: Asterisk calls receiving media commands are implicitly answered

# v0.9.1 - 2012-01-30
  * Bugfix: Closing an disconnected XMPP connection is a no-op

# v0.9.0 - 2012-01-30
  * Bugfix: Remove the rest of the deprecated Tropo components (conference)
  * Feature: Outbound dials on Asterisk now respect the dial timeout
  * Bugfix: Registering stanza handlers on an XMPP connection now sets them in the correct order such that they do not override the internally defined handlers

# v0.8.4 - 2012-01-19
  * Bugfix: End, Ringing & Answered events are allowed to have headers
  * Feature: Dial commands may have an optional timeout

# v0.8.3 - 2012-01-17
  * Feature: Return an error when trying to execute a command for unknown calls/components or when not understood
  * Feature: Log calls/translator shutting down
  * Feature: Calls and components should log their IDs
  * Feature: Components marked as internal should send events directly to the component node
  * Bugfix: Fix Asterisk Call and Component logger IDs
  * Bugfix: Fix a stupidly high log level
  * Bugfix: AGI commands executed by a call/component that are a translation of a Rayo command should be marked internal
  * Bugfix: Asterisk components should sent events via the connection
  * Bugfix: Shutting down an asterisk connection should do a cascading shutdown of the translator and all of its calls
  * Bugfix: Component actors should be terminated once they've sent a complete event
  * Bugfix: Component events should be sent with the call ID
  * Bugfix: AMIAction components do not have a call
  * Bugfix: Add test coverage for comparison of complete events
  * Bugfix: A call being hung up should terminate the call actor
  * Bugfix: Fix a mock expectation error in a test

# v0.8.2 - 2012-01-10
  * Feature: Support outbound dial on Asterisk
  * Bugfix: Asterisk hangup causes should map to correct Rayo End reason

# v0.8.1 - 2012-01-09
  * Feature: Support DTMF Input components on Asterisk

# v0.8.0 - 2012-01-06
  * Feature: Expose Blather's connection timeout config when creating a Connection::XMPP
  * Bugfix: Remove some deprecated Tropo extension components
  * Bugfix: Remove reconnection logic since it really belongs in the consumer
  * Feature: Raise a DisconnectedError when a disconnection is detected

# v0.7.2 - 2011-12-28
  * Feature: Allow sending commands to mixers easily
  * Feature: Allow configuration of Rayo XMPP domains (root, call and mixer)
  * Feature: Log Blather messages to the trace log level
  * Feature: Return an error when trying to execute an Output on Asterisk with unsupported options set
  * Feature: Add basic support for media output via MRCPSynth on Asterisk
  * API change: Rename mixer_id to mixer_name to align with change to Rayo
  * Bugfix: Handle and expose RubySpeech GRXML documents on Input/Ask properly
  * Bugfix: Compare ProtocolErrors correctly
  * Bugfix: Asterisk media output should default to Asterisk native output (STREAM FILE)
  * Bugfix: An Output node's default max_time value should be nil rather than zero

# v0.7.1 - 2011-11-24
  * [FEATURE] Add `Connection#not_ready!`, to instruct the server not to send any more offers.
  * [BUGFIX] Translate all exceptions raised by the XMPP connection into a ProtocolError
  * [UPDATE] Blather dependency to >= 0.5.9

# v0.7.0 - 2011-11-22
  * Bugfix: Some spec mistakes
  * Feature: Allow execution of actions against global components on Asterisk
  * API change: The console has been removed
  * API change: Components no longer expose a FutureResource at #complete_event, and instead wrap its API in the same way as #response and #response=. Any consumer code which does some_component.complete_event.resource or some_component.complete_event.resource= should now use some_component.complete_event and some_component.complete_event=
  * Feature: Added the max-silence attribute to the Input component
  * Bugfix: Bump the Celluloid dependency to avoid spec failures on JRuby and monkey-patching for mockability
  * API change: Event handlers registered on components are no longer triggered by incoming events internally to Punchblock. These events must be consumed via a Client's event handlers or event queue and manually triggered on a component using ComponentNode#trigger_event_handler

# v0.6.2
  # Feature: Added basic support for running Punchblock apps on Asterisk. Calls coming in to AsyncAGI result in the client receiving an Offer, hangup events are sent, and accept/answer/hangup commands work.
  # API change: The logger is now set using Punchblock.logger= rather than as a hash key to Connection.new

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
