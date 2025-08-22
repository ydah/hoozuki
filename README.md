# Hoozuki (鬼灯)

A hobby regex engine written in Ruby. Designed to be simple and efficient for educational purposes.

## Installation

```bash
gem install hoozuki
```

## Usage

```ruby
require 'hoozuki'
regex = Hoozuki::Regex.new('a(bc|de)f')
puts regex.match?('abcdef') # => true
puts regex.match?('adef')   # => true
puts regex.match?('xyz')    # => false
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
