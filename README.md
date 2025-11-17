# My MacBook Pro Config

This contains Puppet code that configures my MacBook Pro.

# Usage

1. Install the Mac OS X Puppet Agent.

2. Then, install the vcsrepo module:

```bash
sudo puppet module install puppetlabs-vcsrepo
```

3. Clone this repo.  It is assumed that this is installed in `/Users/alexharvey/git/home/mac`. (*IF NOT* replace all references in common.yaml.)

4. Link the real hiera.yaml and hieradata files:

5. Double check that these details are applicable to the Mac from [./hieradata/common.yaml](./hieradata/common.yaml):

```yaml
---
me: alexharvey
full_me: Alex Harvey
home: /Users/alexharvey
```

```bash
sudo bash -c '
  cd /etc/puppetlabs/puppet
  mv -f hiera.yaml hiera.yaml.orig
  ln -s /Users/alexharvey/git/home/mac/hiera.yaml.real hiera.yaml
  ln -s /Users/alexharvey/git/home/mac/hieradata hieradata
'
```

6. Ensure Puppet is in the path:

```bash
export PATH=/opt/puppetlabs/bin:"$PATH"
```

7. Export the laptop password (zsh version):

```zsh
read "FACTER_laptop_password?Enter laptop password: "
export FACTER_laptop_password
```

(Bash version):

```bash
read -rsp "Enter laptop password: " FACTER_laptop_password
echo
export FACTER_laptop_password
```

8. Finally:

```text
sudo -E puppet apply mac.pp
```

# Testing

To run the Rspec-puppet tests as usual:

```text
bundle config set --local without 'system_tests'
bundle install
bundle exec rake spec
```
