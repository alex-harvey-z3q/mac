#!/usr/bin/env puppet apply

$me      = lookup('me')
$full_me = lookup('full_me')
$home    = lookup('home')

Exec {
  path => '/bin:/usr/bin:/usr/local/bin',
  user => $me,
  cwd  => $home,
  environment => ["HOME=${home}"],
}

define pkg(
  Enum['present'] $ensure,
  Enum['brew','brewcask','pip','rvm'] $provider,
  ) {

  case $provider {
    'brew': {
      exec { "brew install $name":
        unless => "brew list $name",
      }
    }
    'brewcask': {
      exec { "brew cask install $name":
        unless => "brew list $name",
      }
    }
    'pip': {
      exec { "pip install $name":
        unless => "pip show $name",
      }
    }
    'rvm': {
      exec { "rvm install ruby-$name":
        unless => "rvm list | grep -q ruby-$name",
      }
    }
  }
}

class brew (
  String $laptop_password,
  Array[String] $pkgs,
  Array[String] $casks,
  ) {

  file { '/var/root/pw.sh':
    ensure  => file,
    mode    => '0700',
    content => "#!/bin/bash\necho ${laptop_password}",
  }
  ->
  exec { 'install homebrew':
    command     => 'echo "" | bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"',
    environment => ["USER=${::me}", "SUDO_ASKPASS=/var/root/pw.sh", "HOME=${::home}"],
    timeout     => 0,
    creates     => '/usr/local/bin/brew',
  }

  pkg { $pkgs:
    ensure   => present,
    provider => 'brew',
    require  => Exec['install homebrew'],
  }

  pkg { $casks:
    ensure   => present,
    provider => 'brewcask',
    require  => Exec['install homebrew'],
  }
}

class ssh (
  String $id_rsa,
  ) {

  file { "${::home}/.ssh":
    ensure => directory,
    owner  => $::me,
    mode   => '0700',
  }

  file { "${::home}/.ssh/id_rsa":
    ensure  => file,
    content => $id_rsa,
    owner   => $::me,
    mode    => '0600',
  }
}

class dotfiles {
  vcsrepo { "${::home}/git/home/dotfiles":
    ensure   => present,
    provider => git,
    source   => 'git@github.com:alexharv074/dotfiles.git',
    user     => $::me,
  }
  ->
  exec { 'dotfiles':
    command => 'bash git/home/dotfiles/install.sh',
    unless  => "ls -la ${::home} | grep -q git/home/dotfiles",
    require => Vcsrepo["${::home}/git/home/dotfiles"],
  }
}

class shells (
  String $shells,
  ) {
  file { '/etc/shells':
    ensure  => file,
    content => $shells,
  }

  include shells::bash
  include shells::zsh
}

class shells::bash {
  pkg { ['bash', 'bash-completion']:
    ensure => present,
    provider => 'brew',
  }
  ->
  exec { 'link-bash':
    command => 'brew link bash',
    creates => '/usr/local/bin/bash',
  }
}

class shells::zsh {
  pkg { ['zsh', 'zsh-completions']:
    ensure   => present,
    provider => 'brew',
  }

  user { $::me:
    ensure  => present,
    shell   => '/usr/local/bin/zsh',
    require => Pkg['zsh'],
  }

  exec { 'install oh-my-zsh':
    command => 'sh -c "$(curl -fsSL https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh)"',
    creates => "${::home}/.oh-my-zsh",
  }

  file { "${::home}/.antigen":
    ensure => directory,
    owner  => $::me,
  }
  ->
  exec { 'install antigen':
    command => "curl -L git.io/antigen > ${::home}/.antigen/antigen.zsh",
    creates => "${::home}/.antigen/antigen.zsh",
  }
}

class vim (
  Hash[String, String] $vimplugs,
  ) {

  file { ["${::home}/.vim", "${::home}/.vim/autoload", "${::home}/.vim/bundle"]:
    ensure => directory,
    owner  => $::me,
  }

  exec { 'install pathogen':
    command => "curl -LSso ${::home}/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim",
    path    => '/bin:/usr/bin',
    user    => $::me,
    creates => "${::home}/.vim/autoload/pathogen.vim",
  }

  $vimplugs.each |$dir, $source| {
    vcsrepo { "${::home}/.vim/bundle/$dir":
      ensure   => present,
      provider => git,
      source   => $source,
      user     => $::me,
      require  => File["${::home}/.vim/bundle"],
    }
  }
}

class ruby (
  Array[String] $rubies,
  ) {

  exec { 'install rvm':
    command => 'curl -sSL https://get.rvm.io | bash -s stable --ruby',
    creates => "${::home}/.rvm/bin/rvm",
  }

  $rubies.each |$ruby| {
    pkg { $ruby:
      ensure   => present,
      provider => 'rvm',
      require  => Exec['install rvm'],
    }
  }
}

class shunit {
  vcsrepo { "${::home}/git/home/shunit2":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/kward/shunit2.git',
    user     => $::me,
  }
  ->
  file { '/usr/local/bin/shunit2':
    ensure => link,
    target => "${::home}/git/home/shunit2/shunit2",
  }
}

include brew
include ssh
include dotfiles
include shells
include vim
include ruby
include shunit

# vim:ft=puppet
