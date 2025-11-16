# My MacBook Pro Config

This contains Puppet code that configures my MacBook Pro.

# Usage

1. Install the Mac OS X Puppet Agent.

2. Ensure Homebrew is installed and install it if it's not. See its [home page](https://brew.sh/).

3. Then, install the vcsrepo module:

```bash
sudo puppet module install puppetlabs-vcsrepo
```

4. Clone this repo.  It is assumed that this is installed in `/Users/alexharvey/git/home/mac`. (*IF NOT* replace all references in common.yaml.)

5. Link the real hiera.yaml and hieradata files:

6. Double check that these details are applicable to the Mac from [./hieradata/common.yaml](./hieradata/common.yaml):

```yaml
---
me: alexharvey
full_me: Alex Harvey
home: /Users/alexharvey
```

```bash
sudo cd /etc/puppetlabs/puppet && \
  mv -f hiera.yaml hiera.yaml.orig && \
  ln -s /Users/alexharvey/git/home/mac/hiera.yaml.real hiera.yaml && \
  ln -s /Users/alexharvey/git/home/mac/hieradata
```

7. Ensure Puppet is in the path:

```bash
export PATH=/opt/puppetlabs/bin:"$PATH"
```

8. Export the laptop password (zsh version):

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

9. Finally:

```text
sudo -E puppet apply mac.pp
```

# Testing

To run the Rspec-puppet tests as usual:

```text
bundle install --without system_tests
bundle exec rake spec
```
