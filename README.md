# My MacBook Pro Config

This contains Puppet code that configures my MacBook Pro.

# Usage

1. Install the Mac OS X Puppet Agent.

1. Ensure Homebrew is installed and install it if it's not. See its [home page](https://brew.sh/).

1. Then, install the vcsrepo module:

```bash
sudo puppet module install puppetlabs-vcsrepo
```

1. Clone this repo.  It is assumed that this is installed in `/Users/alexharvey/git/home/mac`. (*IF NOT* replace all references in common.yaml.)

1. Link the real hiera.yaml and hieradata files:

1. Double check that these details are applicable to the Mac from [./hieradata/common.yaml](./hieradata/common.yaml):

```yaml
---
me: alexharvey
full_me: Alex Harvey
home: /Users/alex.harvey
```

```bash
sudo cd /etc/puppetlabs/puppet && \
  mv -f hiera.yaml hiera.yaml.orig && \
  ln -s /Users/alexharvey/git/home/mac/hiera.yaml.real hiera.yaml && \
  ln -s /Users/alexharvey/git/home/mac/hieradata
```

1. Ensure Puppet is in the path:

```bash
export PATH=/opt/puppetlabs/bin:"$PATH"
```

1. Export the laptop password (zsh version):

```zsh
read "FACTER_laptop_password?Enter laptop password: "
export FACTER_laptop_password
```

1. Finally:

```text
sudo -E puppet apply mac.pp
```

# Testing

To run the Rspec-puppet tests as usual:

```text
bundle install --without system_tests
bundle exec rake spec
```
