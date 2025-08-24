# Hoozuki (鬼灯) [![Gem Version](https://badge.fury.io/rb/hoozuki.svg)](https://badge.fury.io/rb/hoozuki) [![CI](https://github.com/ydah/hoozuki/actions/workflows/ci.yml/badge.svg)](https://github.com/ydah/hoozuki/actions/workflows/ci.yml)

A hobby regex engine written in Ruby. Designed to be simple and efficient for educational purposes.
Currently supports 2 engines:
- NFA Based Engine
- VM Based Engine

## Installation

```bash
gem install hoozuki
```

## Usage

```ruby
require 'hoozuki'
regex = Hoozuki.new('a(bc|de)*f') # Or Hoozuki.new('a(bc|de)*f', engine: :nfa) for NFA based engine
regex.match?('abcdef') # => true
regex.match?('adef')   # => true
regex.match?('xyz')    # => false
```

If you want to use the VM based engine:

```ruby
require 'hoozuki'
regex = Hoozuki.new('a(bc|de)*f', engine: :vm)
regex.match?('abcdef') # => true
regex.match?('adef')   # => true
regex.match?('xyz')    # => false
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
