source 'https://rubygems.org'

group :development do
  gem 'pry'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'hashdiff'
end

gem 'facter'

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion
else
  gem 'puppet'
end
