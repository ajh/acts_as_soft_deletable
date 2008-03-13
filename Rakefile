require 'rubygems'
require 'rake/testtask'

namespace :test do
  %w(sqlite sqlite3 postgresql mysql).each do |adapter|

    desc "Test the plugin with #{adapter}"
    Rake::TestTask.new(adapter) do |t|
      t.libs << "test/connections/#{adapter}"
      t.pattern = 'test/**/test_*.rb'
      t.verbose = true
    end

  end
end

desc 'Test the plugin for all databases'
task :test => ["test:sqlite", "test:sqlite3", "test:postgresql", "test:mysql"] 

desc 'Default: run unit tests'
task :default => :test

