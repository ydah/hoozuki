# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace 'build' do
  desc 'build parser from parser.y'
  task :parser do
    sh 'bundle exec racc lib/hoozuki/parser.y --embedded --frozen -o lib/hoozuki/parser.rb -t --log-file=parser.output'
  end
end
