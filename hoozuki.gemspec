# frozen_string_literal: true

require_relative 'lib/hoozuki/version'

Gem::Specification.new do |spec|
  spec.name = 'hoozuki'
  spec.version = Hoozuki::VERSION
  spec.authors = ['Yudai Takada']
  spec.email = ['t.yudai92@gmail.com']

  spec.summary               = 'A hobby regex engine written in Ruby.'
  spec.description           = 'Hoozuki is a hobby regex engine written in Ruby, designed to be simple and efficient for educational purposes.'
  spec.homepage              = 'https://github.com/ydah/hoozuki'
  spec.license               = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .github/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
