require 'rubygems'
require 'rake/testtask'
require 'rake/rdoctask'

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

Rake::RDocTask.new("doc") do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.template = ENV['template'] if ENV['template']
  rdoc.title    = "Acts As Soft Deletable Documentation"
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('README')
end
