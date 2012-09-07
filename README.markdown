# Punchblock
Punchblock is a middleware library for telephony applications. Like Rack is to Rails and Sinatra, Punchblock provides a consistent API on top of several underlying third-party call control protocols.

In the same spirit that inspired Rack, the Punchblock library is envisioned to be the single library for call control wiring. Frameworks and applications may take advantage of Punchblock's single API to write powerful code for managing calls. Punchblock is not and will not be an application framework; rather it only surfaces the various protocols and presents a consistent interface to its consumers. NB: If you're looking to develop an application, you should take a look at the [Adhearsion](http://adhearsion.com) framework first. This library is much lower level.

## Installation
    gem install punchblock

## Usage

The best available usage documentation available for Punchblock is by example, in Adhearsion.

## Supported Protocols

* Rayo
* Asterisk (AMI & AsyncAGI)

## Links:
* [Source](https://github.com/adhearsion/punchblock)
* [Documentation](http://rdoc.info/github/adhearsion/punchblock/master/frames)
* [Bug Tracker](https://github.com/adhearsion/punchblock/issues)

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  * If you want to have your own version, that is fine but bump version in a commit by itself so I can ignore when I pull
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2012 Adhearsion Foundation Inc. MIT licence (see LICENSE for details).
