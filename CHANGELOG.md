# [develop](https://github.com/adhearsion/punchblock)
  * Feature: Support RubySpeech builtin grammars on Asterisk and FreeSWITCH
  * Feature: Output on Asterisk supports a new `:native_or_unimrcp` renderer which allows for fallback of output rendering from Asterisk native when possible, to a TTS engine when it's not.
  * Bugfix: Reject commands against components which have finished on Asterisk, and garbage collect them

# [v2.0.1](https://github.com/adhearsion/punchblock/compare/v2.0.0...v2.0.1) - [2013-09-17](https://rubygems.org/gems/punchblock/versions/2.0.1)
  * Bugfix: Allow audio file URIs with file extensions on Asterisk
  * Bugfix: Input timers were being started before output finished on Asterisk composed prompts
  * Bugfix: Input initial timers were being started on Asterisk composed prompts even if the prompt was barged
  * Bugfix: Output was being interrupted on Asterisk composed prompts at every DTMF keypress, even if the output was already finished

# [v2.0.0](https://github.com/adhearsion/punchblock/compare/v1.9.4...v2.0.0) - [2013-08-29](https://rubygems.org/gems/punchblock/versions/2.0.0)
  * Feature: Compliance with v0.2 of the published Rayo spec (http://xmpp.org/extensions/xep-0327.html)
  * Feature: Add support for Rayo Prompt component
  * Feature: Added FS support for initial timeout and final timeout on Record
  * Change: Models are now plain ruby objects, not XML nodes, and are imported from/exported to XML when necessary for communicating over XMPP.
  * Change: `#headers` and AMI `#attributes` now do not have their names modified. A header of `'Call-ID'` will no longer be modified to `:call_id`.
  * Change: AMI Events/Actions now have `#headers(=)` rather than `#attributes(=)`
  * Change: Remove event queue
  * Change: Removed `media_engine` and `default_voice` settings
  * Bugfix: Reconnect dead Asterisk streams correctly
  * Bugfix: Include AMI response text_body in AMI component complete events
  * Bugfix: Avoid crashing translators (Asterisk or FreeSWITCH) by instructing them to call back to terminated Call objects
  * Bugfix: Detect MRCPSynth failure in output component
  * Bugfix: Handle AMI errors indicating dead channels correctly

# [v1.9.4](https://github.com/adhearsion/punchblock/compare/v1.9.3...v1.9.4) - [2013-06-08](https://rubygems.org/gems/punchblock/versions/1.9.4)
  * Bugfix: Finish more setup before sending output ref on Asterisk
  * Bugfix: Allow early media TTS on Asterisk in addition to audio playback
  * Bugfix: Correctly mark Asterisk calls as answered after successfully executing an answer command

# [v1.9.3](https://github.com/adhearsion/punchblock/compare/v1.9.2...v1.9.3) - [2013-05-16](https://rubygems.org/gems/punchblock/versions/1.9.3)
  * Bugfix: Improve error messages when trying to execute stop commands on components in an invalid state

# [v1.9.2](https://github.com/adhearsion/punchblock/compare/v1.9.1...v1.9.2) - [2013-05-10](https://rubygems.org/gems/punchblock/versions/1.9.2)
  * Bugfix: We were raising an exception on connection shutdown due to waiting for the connection to end incorrectly.
  * Bugfix/Perf: FreeSWITCH Call actors were being kept alive after hangup for no reason
  * Bugfix/Perf: FreeSWITCH component complete events were looping out of the actor
  * Perf: We were wasting CPU cycles listening to all ES events when we really don't need to

# [v1.9.1](https://github.com/adhearsion/punchblock/compare/v1.9.0...v1.9.1) - [2013-05-08](https://rubygems.org/gems/punchblock/versions/1.9.1)
  * Bugfix: AMI errors indicating dead channels were not being handled correctly
  * Bugfix: We were broken on Celluloid 0.14 due to changes in block execution semantics between actors

# [v1.9.0](https://github.com/adhearsion/punchblock/compare/v1.8.2...v1.9.0) - [2013-05-03](https://rubygems.org/gems/punchblock/versions/1.9.0)
  * Feature: Use RubyAMI 2.0 with a single AMI connection.
  * Feature: Cache channel variables on Asterisk calls.
  * Feature: Allow optional sending of end event when breaking from AsyncAGI on Asterisk. This enables dialplan handback. Only triggers if the channel variable 'PUNCHBLOCK_END_ON_ASYNCAGI_BREAK' is set.
  * Bugfix: Avoid DTMF recognizer failures and race conditions by bringing DTMFRecognizer back into the Input component actor.
  * Bugfix: Catch Asterisk AMI errors in all cases and fail accordingly, instead of ploughing ahead in the face of adversity.
  * Bugfix: Improve performance of Asterisk implementation by no longer spinning up a component actor for AGI command execution.

# [v1.8.2](https://github.com/adhearsion/punchblock/compare/v1.8.1...v1.8.2) - [2013-04-19](https://rubygems.org/gems/punchblock/versions/1.8.2)
  * Bugfix: Input initial timeout was being set as a float rather than an integer

# [v1.8.2](https://github.com/adhearsion/punchblock/compare/v1.8.1...v1.8.2) - [2013-04-19](https://rubygems.org/gems/punchblock/versions/1.8.2)
  * Bugfix: Input initial timeout was being set as a float rather than an integer

# [v1.8.1](https://github.com/adhearsion/punchblock/compare/v1.8.0...v1.8.1) - [2013-03-25](https://rubygems.org/gems/punchblock/versions/1.8.1)
  * Bugfix: FreeSWITCH was requiring a from attribute on a dial command
  * Bugfix: Asterisk translator now properly checks for existence of the recordings directory
  * Bugfix: Components should transition state before unblocking
  * Bugfix: Asterisk joins are now more robustly responded to when the join begins
  * Bugfix: On FreeSWITCH, only events relating to bridge start/end should be delivered to bridged calls
  * Bugfix: On FreeSWITCH, a voice value on an audio-only output component should not prevent execution
  * Bugfix: XMPP Ping should be an IQ get, not set
  * Bugfix: Stop command should be in Rayo ext namespace
  * Bugfix: XMPP specs were mistakenly resetting the logger object for other tests.
  * CS: Avoid Celluloid deprecation warnings

# [v1.8.0](https://github.com/adhearsion/punchblock/compare/v1.7.1...v1.8.0) - [2013-01-10](https://rubygems.org/gems/punchblock/versions/1.8.0)
  * Feature: Join command now enforces a list of valid direction attribute values
  * Feature: Added support for media direction to the Record component
  * Feature: Record direction support on FS
  * Bugfix: Fixed answering during early media on FS
  * Bugfix: Doing multiple recordings on Asterisk during the lifetime of a call was crashing Punchblock

# [v1.7.1](https://github.com/adhearsion/punchblock/compare/v1.7.0...v1.7.1) - [2012-12-17](https://rubygems.org/gems/punchblock/versions/1.7.1)
  * Bugfix: Deal with nil media engines on FS/* properly

# [v1.7.0](https://github.com/adhearsion/punchblock/compare/v1.6.1...v1.7.0) - [2012-12-13](https://rubygems.org/gems/punchblock/versions/1.7.0)
  * Feature: Support for the renderer attribute added to the Output component.
  * Feature: FreeSWITCH and Asterisk translators now use the :renderer attribute on Output
  * Bugfix: Fixed scenario where executing the ANSWER application on FreeSWITCH on an already answered call caused FS to stop accepting commands.
  * Bugfix: Plug a severe memory leak
  * Bugfix: Raise an error immediately if trying to execute an invalid media engine on Asterisk
  * Bugfix: Handle a wider variety of types when configuring media engines on Asterisk and FreeSWITCH, such as Strings instead of Symbols

# [v1.6.1](https://github.com/adhearsion/punchblock/compare/v1.6.0...v1.6.1) - [2012-11-14](https://rubygems.org/gems/punchblock/versions/1.6.1)
  * Bugfix: Safer component attribute writer conversion

# [v1.6.0](https://github.com/adhearsion/punchblock/compare/v1.5.3...v1.6.0) - [2012-11-14](https://rubygems.org/gems/punchblock/versions/1.6.0)
  * Feature: Set dial headers on FreeSWITCH originate command (SIP only)
  * Feature: Set dial headers on Asterisk originate command (SIP only)
  * Bugfix: Headers were being re-written downcased and with underscores
  * Bugfix: Ensure all numeric component attributes are written as the correct type

# [v1.5.3](https://github.com/adhearsion/punchblock/compare/v1.5.2...v1.5.3) - [2012-11-01](https://rubygems.org/gems/punchblock/versions/1.5.3)
  * Doc: Add link to docs for unrenderable doc error

# [v1.5.2](https://github.com/adhearsion/punchblock/compare/v1.5.1...v1.5.2) - [2012-10-25](https://rubygems.org/gems/punchblock/versions/1.5.2)
  * Bugfix: Use correct GRXML content type
  * Bugfix: Fix UniMRCP for documents containing commas
  * Bugfix: Bump Celluloid dependency to avoid issues with serialising AMI

# [v1.5.1](https://github.com/adhearsion/punchblock/compare/v1.5.0...v1.5.1) - [2012-10-11](https://rubygems.org/gems/punchblock/versions/1.5.1)
  * Update: Bump Celluloid dependency
  * Bugfix: Input grammars referenced by URL now no longer specify a content type
  * Bugfix: FreeSWITCH `Dial#from` values now parsed more flexibly

# [v1.5.0](https://github.com/adhearsion/punchblock/compare/v1.4.1...v1.5.0) - [2012-10-01](https://rubygems.org/gems/punchblock/versions/1.5.0)
  * Feature: Input component now supports grammar URLs
  * Bugfix: Hanging up Asterisk calls now correctly specifies normal clearing cause
  * Doc: Fix a bunch of API documentation

# [v1.4.1](https://github.com/adhearsion/punchblock/compare/v1.4.0...v1.4.1) - [2012-09-06](https://rubygems.org/gems/punchblock/versions/1.4.1)
  * Bugfix: Cleaning up DTMF handlers for input components with a dead call should not crash on FreeSWITCH
  * Bugfix: Reduced a race condition on FreeSWITCH when dispatching events from calls to dead components
  * Bugfix: Events relevant to bridged channels were not being routed to the call
  * Bugfix: Components using #stop_by_redirect now return an error response if stopped when they are complete
  * Bugfix: Hold back ruby_ami and ruby_fs dependencies pending fixes for Celluloid 0.12.0

# [v1.4.0](https://github.com/adhearsion/punchblock/compare/v1.3.0...v1.4.0) - [2012-08-07](https://rubygems.org/gems/punchblock/versions/1.4.0)
  * Feature: FreeSWITCH support (mostly complete, experimental, proceed with caution)
  * Bugfix: Report the correct caller ID in offers from Asterisk
  * Bugfix: Strip out caller ID name from dial commands on Asterisk

# [v1.3.0](https://github.com/adhearsion/punchblock/compare/v1.2.0...v1.3.0) - [2012-07-22](https://rubygems.org/gems/punchblock/versions/1.3.0)
  * Change: Asterisk output now uses Playback rather than STREAM FILE
  * Feature: The recordings dir is now checked for existence on startup, and logs an error if it is not there. Asterisk only.
  * Feature: Punchblock now logs an error if it was unable to add the redirect context on Asterisk on startup.
  * Feature: Output component now exposes #recording and #recording_uri for easy access to record results.
  * Feature: Early media support for Asterisk, using Progress to start an early media session
  * Feature: Output component on Asterisk now supports early media. If the line is not answered, it runs Progress followed by Playback with noanswer.
  * Feature: Record component on Asterisk now raises if called on an unanswered call
  * Feature: Input component on Asterisk works the same whether the call is answered or unanswered
  * Feature: AMI events are emitted to the relevant calls
  * Feature: Simpler method of getting hold of a new client/connection
  * Bugfix: AMI events are processed in order by the translator
  * Bugfix: Asterisk calls and components are removed from registries when they die
  * Bugfix: Commands for unknown calls/components respond with the correct `:item_not_found` name
  * Bugfix: AMI events relevant to a particular call are emitted by that call to the client
  * Bugfix: Asterisk calls send an error complete event for their dying components
  * Bugfix: Asterisk translator sends an error end event for its dying calls
  * Bugfix: Use the primitive version of AGI ANSWER, rather than an app
  * Bugfix: Outbound calls which never begin progress on Asterisk end with an error
  * Bugfix: Asterisk now responds correctly to unjoin commands
  * Bugfix: Allow nil reject reasons
  * Bugfix: Asterisk translator now does NOT answer the call automatically when Output, Input or Record are used.

# [v1.2.0](https://github.com/adhearsion/punchblock/compare/v1.1.0...v1.2.0) - [2012-04-29](https://rubygems.org/gems/punchblock/versions/1.2.0)
  * Feature: Basic support for record component on Asterisk, using MixMonitor. Currently unsupported options include: start_paused, initial_timeout, final_timeout. Hints are additionally not supported, and recordings are stored on the * machine's local filesystem.

# [v1.1.0](https://github.com/adhearsion/punchblock/compare/v1.0.0...v1.1.0) - [2012-04-26](https://rubygems.org/gems/punchblock/versions/1.1.0)
  * Feature: Implement Reject on Asterisk
  * Bugfix: No longer generate warnings
  * Bugfix: Set 'to' attribute on an offer from Asterisk to something useful if the dnid is 'unknown'
  * Bugfix: Include caller ID name in 'from' attribute on an offer from Asterisk
  * Bugfix: Removed media engine switching on Asterisk Input component - fixes broken input when using app_swift or unimrcp for output
  * Update: Better dependency version fixing

# [v1.0.0](https://github.com/adhearsion/punchblock/compare/v0.12.0...v1.0.0) - [2012-04-11](https://rubygems.org/gems/punchblock/versions/1.0.0)
  * Stable release :D
  * Bugfix: Any issue in compiling an output document into executable elements on Asterisk should return an unrenderable doc error

# [v0.12.0](https://github.com/adhearsion/punchblock/compare/v0.11.0...v0.12.0) - [2012-03-30](https://rubygems.org/gems/punchblock/versions/0.12.0)
  * API Change: `#call_id` and `#mixer_name` attributes changed to `#target_call_id` and `#target_mixer_name`
  * API Change: `#other_call_id` attributes changed to `#call_id` to better align with Rayo

# [v0.11.0](https://github.com/adhearsion/punchblock/compare/v0.10.0...v0.11.0) - [2012-03-29](https://rubygems.org/gems/punchblock/versions/0.11.0)
  * Feature: Input & Output components on Asterisk now responds to a Stop command
  * Feature: started/stopped-speaking events are now handled
  * Bugfix: Asterisk output component considers an SSML doc w/ a string node w/o spaces to be a filename
  * Bugfix: `ProtocolError` should behave like a normal exception, just with extra attributes

# [v0.10.0](https://github.com/adhearsion/punchblock/compare/v0.9.2...v0.10.0) - [2012-03-19](https://rubygems.org/gems/punchblock/versions/0.10.0)
  * Feature: app_swift is now supported on Asterisk with a media_engine type of :swift
  * Feature: Asterisk calls now support the Join API
  * Feature: On Asterisk, Punchblock creates a context and extension to redirect calls to
  * Bugfix: Unjoining calls now redirects both legs
  * Bugfix: Unlink events on Asterisk correctly send Unjoin Punchblock events
  * Bugfix: The Asterisk translator now ignores calls to 'h' or of type 'Kill'
  * Bugfix: Handle more XMPP connection errors gracefully
  * Bugfix: The XMPP connection ready event is now available to external handlers
  * Bugfix: The Asterisk connection now passes the `:media_engine` option down to the translator
  * Bugfix: Connections now always respond to `#connected?`
  * Bugfix: Connection termination handled gracefully on Asterisk

# [v0.9.2](https://github.com/adhearsion/punchblock/compare/v0.9.1...v0.9.2) - [2012-02-18](https://rubygems.org/gems/punchblock/versions/0.9.2)
  * Feature: Asterisk calls receiving media commands are implicitly answered
  * Bugfix: Unrenderable output documents on Asterisk should return a sensible error
  * Bugfix: Log the target of commands correctly
  * Bugfix: Do not wrap exceptions in ProtocolError

# [v0.9.1](https://github.com/adhearsion/punchblock/compare/v0.9.0...v0.9.1) - [2012-01-30](https://rubygems.org/gems/punchblock/versions/0.9.1)
  * Bugfix: Closing an disconnected XMPP connection is a no-op

# [v0.9.0](https://github.com/adhearsion/punchblock/compare/v0.8.4...v0.9.0) - [2012-01-30](https://rubygems.org/gems/punchblock/versions/0.9.0)
  * Bugfix: Remove the rest of the deprecated Tropo components (conference)
  * Feature: Outbound dials on Asterisk now respect the dial timeout
  * Bugfix: Registering stanza handlers on an XMPP connection now sets them in the correct order such that they do not override the internally defined handlers

# [v0.8.4](https://github.com/adhearsion/punchblock/compare/v0.8.3...v0.8.4) - [2012-01-19](https://rubygems.org/gems/punchblock/versions/0.8.4)
  * Bugfix: End, Ringing & Answered events are allowed to have headers
  * Feature: Dial commands may have an optional timeout

# [v0.8.3](https://github.com/adhearsion/punchblock/compare/v0.8.2...v0.8.3) - [2012-01-17](https://rubygems.org/gems/punchblock/versions/0.8.3)
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

# [v0.8.2](https://github.com/adhearsion/punchblock/compare/v0.8.1...v0.8.2) - [2012-01-10](https://rubygems.org/gems/punchblock/versions/0.8.2)
  * Feature: Support outbound dial on Asterisk
  * Bugfix: Asterisk hangup causes should map to correct Rayo End reason

# [v0.8.1](https://github.com/adhearsion/punchblock/compare/v0.8.0...v0.8.1) - [2012-01-09](https://rubygems.org/gems/punchblock/versions/0.8.1)
  * Feature: Support DTMF Input components on Asterisk

# [v0.8.0](https://github.com/adhearsion/punchblock/compare/v0.7.2...v0.8.0) - [2012-01-06](https://rubygems.org/gems/punchblock/versions/0.8.0)
  * Feature: Expose Blather's connection timeout config when creating a Connection::XMPP
  * Bugfix: Remove some deprecated Tropo extension components
  * Bugfix: Remove reconnection logic since it really belongs in the consumer
  * Feature: Raise a DisconnectedError when a disconnection is detected

# [v0.7.2](https://github.com/adhearsion/punchblock/compare/v0.7.1...v0.7.2) - [2011-12-28](https://rubygems.org/gems/punchblock/versions/0.7.2)
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

# [v0.7.1](https://github.com/adhearsion/punchblock/compare/v0.7.0...v0.7.1) - [2011-11-24](https://rubygems.org/gems/punchblock/versions/0.7.1)
  * [FEATURE] Add `Connection#not_ready!`, to instruct the server not to send any more offers.
  * [BUGFIX] Translate all exceptions raised by the XMPP connection into a ProtocolError
  * [UPDATE] Blather dependency to >= 0.5.9

# [v0.7.0](https://github.com/adhearsion/punchblock/compare/v0.6.2...v0.7.0) - [2011-11-22](https://rubygems.org/gems/punchblock/versions/0.7.0)
  * Bugfix: Some spec mistakes
  * Feature: Allow execution of actions against global components on Asterisk
  * API change: The console has been removed
  * API change: Components no longer expose a FutureResource at #complete_event, and instead wrap its API in the same way as #response and #response=. Any consumer code which does some_component.complete_event.resource or some_component.complete_event.resource= should now use some_component.complete_event and some_component.complete_event=
  * Feature: Added the max-silence attribute to the Input component
  * Bugfix: Bump the Celluloid dependency to avoid spec failures on JRuby and monkey-patching for mockability
  * API change: Event handlers registered on components are no longer triggered by incoming events internally to Punchblock. These events must be consumed via a Client's event handlers or event queue and manually triggered on a component using ComponentNode#trigger_event_handler

# [v0.6.2](https://github.com/adhearsion/punchblock/compare/v0.6.1...v0.6.2)
  # Feature: Added basic support for running Punchblock apps on Asterisk. Calls coming in to AsyncAGI result in the client receiving an Offer, hangup events are sent, and accept/answer/hangup commands work.
  # API change: The logger is now set using Punchblock.logger= rather than as a hash key to Connection.new

# [v0.6.1](https://github.com/adhearsion/punchblock/compare/v0.6.0...v0.6.1)
  * Feature: Allow instructing the connection we are ready. An XMPP connection will send initial presence with a status of 'chat' to the rayo domain
  * Bugfix: When running on Asterisk, two FullyBooted events will now trigger a connected event
  * Bugfix: No longer ignore offers from the specified rayo domain on XMPP connections
  * Feature: Tag all event objects with the XMPP domain they came from

# [v0.6.0](https://github.com/adhearsion/punchblock/compare/v0.5.1...v0.6.0)
  * API change: Punchblock consumers now need to instantiate both a Connection and a Client (see the punchblock-console gem for an example)
  * Feature: Added a Connection for Asterisk, utilising RubyAMI to open an AMI connection to Asterisk, and allowing AMI actions to be executed. AMI events are handled by the client event handler.
  * Deprecation: The punchblock-console and the associated DSL are now deprecated and the punchblock-console gem should be used instead

# [v0.5.1](https://github.com/adhearsion/punchblock/compare/v0.5.0...v0.5.1)
  API change: Connections now raise a Punchblock::Connection::Connected instance as an event, rather than the class itself

# [v0.5.0](https://github.com/adhearsion/punchblock/compare/v0.4.3...v0.5.0)
  * Refactoring/API change: Client and connection level concerns are now separated, and one must create a Connection to be passed to a Client on creation. Client now has the choice between an event queue and guarded event handlers.

# [v0.4.3](https://github.com/adhearsion/punchblock/compare/v0.4.2...v0.4.3)
  * Feature: Support for meta-data on recordings (size & duration)
  * Feature: Allow specifying all of Blather's setup options (required to use PB as an XMPP component)
  * Bugfix: Rayo events are discarded if they don't come from the specified domain
  * Bugfix: Component execution in the sample DSL now doesn't expect events on the main queue

# [v0.4.2](https://github.com/adhearsion/punchblock/compare/v0.4.1...v0.4.2)
  * Bugfix: Conference complete event was not being handled

# [v0.4.1](https://github.com/adhearsion/punchblock/compare/v0.4.0...v0.4.1)
  * Feature/API change: Components no longer have an event queue, but instead it is possible to define guarded event handlers via #register_event_handler

# v0.4.0
  * First public release
