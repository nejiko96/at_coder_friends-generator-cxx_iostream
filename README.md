[![Gem Version](https://badge.fury.io/rb/at_coder_friends-generator-cxx_iostream.svg)](https://badge.fury.io/rb/at_coder_friends-generator-cxx_iostream)
![Gem](https://img.shields.io/gem/dt/at_coder_friends-generator-cxx_iostream)
[![Ruby](https://github.com/nejiko96/at_coder_friends-generator-cxx_iostream/actions/workflows/ruby.yml/badge.svg)](https://github.com/nejiko96/at_coder_friends-generator-cxx_iostream/actions/workflows/ruby.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/d09d6944c51982d660cd/maintainability)](https://codeclimate.com/github/nejiko96/at_coder_friends-generator-cxx_iostream/maintainability)
![GitHub](https://img.shields.io/github/license/nejiko96/at_coder_friends-generator-cxx_iostream)

# AtCoderFriends::Generator::CxxIostream

C++(iostream) source generator for [AtCoderFriends](https://github.com/nejiko96/at_coder_friends).  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'at_coder_friends-generator-cxx_iostream'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install at_coder_friends-generator-cxx_iostream

## Configuration

Add ```CxxIostream``` to ```generators``` setting in ```.at_coder_friends.yml```

## Generator Options

Following options are available  
in ```generator_settings/CxxIostream``` section of ```.at_coder_friends.yml```:

| Option | Description | Default |
|---------|-------------|---------|
|default_template|Source template file path|[/templates/cxx_iostream.cxx.erb](/templates/cxx_iostream.cxx.erb)|
|use_global|if set to true, stores input data in global variables|nil|

## ```.at_coder_friends.yml``` example
  ```YAML
  generators:
    - CxxIoStream
  generator_settings:
    CxxIoStream:
      default_template: /path/to/template
      use_global: true
  ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/at_coder_friends-generator-cxx_iostream. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/at_coder_friends-generator-cxx_iostream/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AtCoderFriends::Generator::CxxIostream project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/at_coder_friends-generator-cxx_iostream/blob/master/CODE_OF_CONDUCT.md).
