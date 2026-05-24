#!/usr/bin/env puppet apply

if (! defined('$laptop_password')) {
  fail('export FACTER_laptop_password')
}

$me          = lookup('me')
$full_me     = lookup('full_me')
$home        = lookup('home')
$git_home    = lookup('git_home')
$github_name = lookup('github_name')

Exec {
  path => '/opt/homebrew/bin:/bin:/usr/bin:/usr/local/bin',
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
      exec { "brew install ${name}":
        unless => "brew list ${name}",
      }
    }
    'brewcask': {
      exec { "brew install --cask ${name}":
        unless => "brew list --cask ${name}",
      }
    }
    'pip': {
      exec { "pip install ${name}":
        unless => "pip show ${name}",
      }
    }
    'rvm': {
      exec { "rvm install ruby-${name}":
        unless => "rvm list | grep -q ruby-${name}",
      }
    }
    default: {
      fail("Unsupported package provider ${provider}")
    }
  }
}

define python::version(
  String $version = $title,
  ) {

  exec { "pyenv install ${version}":
    command => "/bin/sh -c '${home}/.pyenv/bin/pyenv install -s ${version}'",
    onlyif  => "/bin/sh -c '/bin/test -x ${home}/.pyenv/bin/pyenv && ! ${home}/.pyenv/bin/pyenv versions --bare | /usr/bin/grep -qx ${version}'",
    user    => $me,
    cwd     => $home,
    require => Vcsrepo["${home}/.pyenv"],
  }
}

class brew (
  Array[String] $pkgs,
  Array[String] $casks,
  ) {

  $app_management_marker = "${home}/.cache/puppet/app-management-settings-opened"
  $app_management_url = 'x-apple.systempreferences:com.apple.preference.security?Privacy_AppBundles'
  $cask_check = "/bin/sh -c 'for cask in ${casks.join(' ')}; do brew list --cask \"\$cask\" >/dev/null 2>&1 || exit 1; done'"

  exec { 'install homebrew':
    command     => '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"',
    environment => [
      'NONINTERACTIVE=1',
      "USER=${facts['me']}",
      "HOME=${facts['home']}",
    ],
    timeout     => 0,
    creates     => '/opt/homebrew/bin/brew',
  }

  -> pkg { $pkgs:
    ensure   => present,
    provider => 'brew',
  }

  # Open the privacy pane once before installing casks that may need
  # App Management approval, then continue on the assumption that I have
  # granted access.
  -> exec { 'open app management settings':
    command   => "mkdir -p ${home}/.cache/puppet && open \"${app_management_url}\" && touch ${app_management_marker}",
    creates   => $app_management_marker,
    unless    => $cask_check,
    logoutput => true,
  }

  -> pkg { $casks:
    ensure   => present,
    provider => 'brewcask',
  }
}

define appstore_app(
  Integer $id,
  ) {

  exec { "mas install ${name}":
    command => "/bin/sh -c '/opt/homebrew/bin/mas install ${id}'",
    onlyif  => "/bin/sh -c '/bin/test -x /opt/homebrew/bin/mas && ! /opt/homebrew/bin/mas list | /usr/bin/grep -q \"^${id} \"'",
    require => Pkg['mas'],
  }
}

class ssh {
  file { "${home}/.ssh":
    ensure => directory,
    owner  => $me,
    mode   => '0700',
  }
}

class dotfiles {
  vcsrepo { "${git_home}/dotfiles":
    ensure   => present,
    provider => git,
    source   => "git@github.com:${github_name}/dotfiles.git",
    user     => $me,
  }

  -> exec { 'dotfiles':
    command => "/bin/bash ${git_home}/dotfiles/install.sh",
    cwd     => $home,
    creates => "${home}/.gitconfig",
    require => Vcsrepo["${git_home}/dotfiles"],
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
    ensure   => present,
    provider => 'brew',
  }

  -> exec { 'link-bash':
    command => 'brew link bash',
    creates => '/opt/homebrew/bin/bash',
  }
}

class shells::zsh (
  String $repo_root = "${git_home}/mac",
  ) {
  pkg { ['zsh', 'zsh-completions']:
    ensure   => present,
    provider => 'brew',
  }

  file { ['/usr/local/share/zsh', '/usr/local/share/zsh/site-functions']:
    ensure => directory,
    mode   => '0755',
  }

  ['_rake', '_bundle', '_rake_tasks'].each |$completion| {
    file { "/usr/local/share/zsh/site-functions/${completion}":
      ensure  => file,
      mode    => '0644',
      source  => "file://${repo_root}/files/zsh/site-functions/${completion}",
      require => File['/usr/local/share/zsh/site-functions'],
    }
  }

# I don't think I want this any more:
#
#  exec { 'install oh-my-zsh':
#    command => 'sh -c "$(curl -fsSL https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh)"',
#    creates => "${home}/.oh-my-zsh",
#  }
#
#  file { "${home}/.antigen":
#    ensure => directory,
#    owner  => $me,
#  }
#  ->
#  exec { 'install antigen':
#    command => "curl -L git.io/antigen > ${home}/.antigen/antigen.zsh",
#    creates => "${home}/.antigen/antigen.zsh",
#  }
#
#  file { ['/usr/local/share/zsh','/usr/local/share/zsh/site-functions']:
#    ensure  => directory,
#    owner   => $me,
#    group   => 'admin',
#    mode    => '755',
#    require => Pkg['zsh'],
#  }
}

class vim (
  Hash[String, String] $vimplugs,
  ) {

  file { ["${home}/.vim", "${home}/.vim/autoload", "${home}/.vim/bundle"]:
    ensure => directory,
    owner  => $me,
  }

  exec { 'install pathogen':
    command => "curl -LSso ${home}/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim",
    path    => '/bin:/usr/bin',
    user    => $me,
    creates => "${home}/.vim/autoload/pathogen.vim",
  }

  $vimplugs.each |$dir, $source| {
    vcsrepo { "${home}/.vim/bundle/${dir}":
      ensure   => present,
      provider => git,
      source   => $source,
      user     => $me,
      require  => File["${home}/.vim/bundle"],
    }
  }
}

class ruby {
  exec { 'install rvm':
    command => 'curl -sSL https://get.rvm.io | bash -s stable --ruby',
    creates => "${home}/.rvm",
  }
}

class shunit {
  vcsrepo { "${git_home}/shunit2":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/kward/shunit2.git',
    user     => $me,
  }

  -> file { '/usr/local/bin/shunit2':
    ensure => link,
    target => "${git_home}/shunit2/shunit2",
  }
}

define github_repo(
  String $repo,
  ) {

  $repo_path = "${git_home}/${repo}"
  $repo_source = "git@github.com:${github_name}/${repo}.git"

  exec { "set origin for ${title}":
    command => "/usr/bin/git -C ${repo_path} remote set-url origin ${repo_source}",
    onlyif  => "/bin/test -d ${repo_path}/.git",
    unless  => "/usr/bin/git -C ${repo_path} remote get-url origin | /usr/bin/grep -Fxq ${repo_source}",
  }

  -> vcsrepo { $repo_path:
    ensure   => present,
    provider => git,
    source   => $repo_source,
    user     => $me,
  }
}

define repo_link(
  String $repo,
  String $source,
  String $target,
  ) {

  $repo_path = "${git_home}/${repo}"

  github_repo { $repo:
    repo => $repo,
  }

  file { $target:
    ensure  => link,
    target  => "${repo_path}/${source}",
    require => Github_repo[$repo],
  }
}

define repo_installer(
  String $repo,
  String $command,
  String $creates,
  ) {

  $repo_path = "${git_home}/${repo}"

  github_repo { $repo:
    repo => $repo,
  }

  exec { "install ${title}":
    command => "/bin/bash ${repo_path}/${command}",
    cwd     => $repo_path,
    creates => $creates,
    require => Github_repo[$repo],
  }
}

class repo_links (
  Hash[String, Hash] $links,
  ) {

  $links.each |$link_name, $params| {
    repo_link { $link_name:
      * => $params,
    }
  }
}

class repo_installers (
  Hash[String, Hash] $installers,
  ) {

  $installers.each |$installer_name, $params| {
    repo_installer { $installer_name:
      * => $params,
    }
  }
}

class python (
  Array[String] $versions,
  ) {

  vcsrepo { "${home}/.pyenv":
    ensure   => present,
    provider => git,
    source   => 'https://github.com/pyenv/pyenv.git',
    user     => $me,
    require  => Pkg['pyenv'],
  }

  python::version { $versions: }

  $global_version = $versions[0]

  exec { "pyenv global ${global_version}":
    command => "/bin/sh -c '${home}/.pyenv/bin/pyenv global ${global_version}'",
    onlyif  => "/bin/sh -c '/bin/test -x ${home}/.pyenv/bin/pyenv && ! ${home}/.pyenv/bin/pyenv global | /usr/bin/grep -qx ${global_version}'",
    user    => $me,
    cwd     => $home,
    require => Python::Version[$global_version],
  }
}

class settings {
  exec { 'disable mission control space rearranging':
    command => '/usr/bin/defaults write com.apple.dock mru-spaces -bool false && /usr/bin/killall Dock',
    unless  => '/usr/bin/defaults read com.apple.dock mru-spaces | /usr/bin/grep -qx 0',
  }

  exec { 'disable recent items':
    command => '/usr/bin/defaults write NSGlobalDomain NSRecentDocumentsLimit -int 0',
    unless  => '/usr/bin/defaults read NSGlobalDomain NSRecentDocumentsLimit | /usr/bin/grep -qx 0',
  }
}

class appstore (
  Hash[String, Integer] $apps,
  ) {

  $apps.each |$app_name, $id| {
    appstore_app { $app_name:
      id => $id,
    }
  }
}

class chrome (
  Hash[String, String] $extensions,
  ) {

  $extension_update_url = 'https://clients2.google.com/service/update2/crx'
  $extension_forcelist_entries = $extensions.map |$name, $id| {
    "    <string>${id};${extension_update_url}</string>"
  }
  $extension_forcelist = $extension_forcelist_entries.join("\n")

  file { '/Library/Managed Preferences':
    ensure => directory,
    owner  => root,
    group  => wheel,
    mode   => '0755',
  }

  file { '/Library/Managed Preferences/com.google.Chrome.plist':
    ensure  => file,
    owner   => root,
    group   => wheel,
    mode    => '0644',
    require => File['/Library/Managed Preferences'],
    content => @(PLIST/L),
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>ExtensionInstallForcelist</key>
        <array>
      ${extension_forcelist}
        </array>
      </dict>
      </plist>
      | PLIST
  }
}

include brew
include appstore
include chrome
include ssh
include dotfiles
include shells
include vim
include ruby
include shunit
include repo_links
include repo_installers
include python
include settings

# vim:ft=puppet
