# My MacBook Pro Config

This contains Puppet code that configures my MacBook Pro.

# Usage

Ensure Puppet is in the path:

~~~ text
export PATH=/opt/puppetlabs/bin:"$PATH"
~~~

Install the Mac OS X Puppet Agent.

Once installed, copy the secret Hiera keys to `/root/keys`.

~~~ text
Alexs-MacBook-Pro:~ root# find /var/root/keys -ls -type f
4297026430        0 dr-x------    4 root             wheel                 128 Jul 29 15:50 /var/root/keys
4297026373        8 -r--------    1 root             wheel                1050 Jul 29 15:47 /var/root/keys/public_key.pkcs7.pem
4297026372        8 -r--------    1 root             wheel                1675 Jul 29 15:47 /var/root/keys/private_key.pkcs7.pem
~~~

Then, install the vcsrepo module:

~~~ text
sudo puppet module install puppetlabs-vcsrepo
~~~

It's assumed that this is installed in `/Users/alexharvey/git/home/mac`.

Link the real hiera.yaml and hieradata files:

~~~ text
sudo cd /etc/puppetlabs/puppet && \
  mv -f hiera.yaml hiera.yaml.orig && \
  mv -f hieradata hieradata.orig && \
  ln -s /Users/alexharvey/git/home/mac/hiera.yaml.real hiera.yaml && \
  ln -s /Users/alexharvey/git/home/mac/hieradata
~~~

Finally:

~~~ text
sudo puppet apply mac.pp
~~~

# Testing

To run the Rspec-puppet tests as usual:

~~~ text
bundle install --without system_tests
bundle exec rake spec
~~~
