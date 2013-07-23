# role-auth

there is no inheritance between permissions created within a role block

there is inheritance between task definitions

## Installation

Add this line to your application's Gemfile:

    gem 'sequel-localize'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sequel-localize

## Usage

TODO: Write usage instructions here

## Assumptions

* changes to the object are finished before the update hook
** merb before: Filters are executed in order of definition
* standard REST Controller
* on scopes defined on the Model

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## TODO
* give possibility to inspect rules
** Hints why it failed
** nice Printout of ruby code
* docs
* publish

## Ideas

* Adapter specific way of finding roles
* custom aliases

## Notes
* Inheritance between parts of roles is bad. It can have unintended side effects.

## Copyright

Copyright (c) 2010 Jonas von Andrian. See LICENSE for details.
