# My MacBook Pro Config

This contains Puppet code that configures my MacBook Pro.

# Usage

1. Install the Mac OS X Puppet Agent.

1. Then, install the vcsrepo module:

~~~ text
sudo puppet module install puppetlabs-vcsrepo
~~~

1. Clone this repo.  It is assumed that this is installed in `/Users/alexharvey/git/home/mac`.

1. Link the real hiera.yaml and hieradata files:

~~~ text
sudo cd /etc/puppetlabs/puppet && \
  mv -f hiera.yaml hiera.yaml.orig && \
  mv -f hieradata hieradata.orig && \
  ln -s /Users/alexharvey/git/home/mac/hiera.yaml.real hiera.yaml && \
  ln -s /Users/alexharvey/git/home/mac/hieradata
~~~

1. Ensure Puppet is in the path:

~~~ text
export PATH=/opt/puppetlabs/bin:"$PATH"
~~~

1. Export the laptop password:

~~~ text
export FACTER_laptop_password=xxxxxxxx
~~~

1. Finally:

~~~ text
sudo -E puppet apply mac.pp
~~~

# Testing

To run the Rspec-puppet tests as usual:

~~~ text
bundle install --without system_tests
bundle exec rake spec
~~~
