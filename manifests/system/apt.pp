## Class rjil::system::apt
## Purpose: configure apt sources
#
#
# == Parameters
#   [override_repo] specifies the location to an optional override_repo that should be previously set up on disk.
#     This is intended to be used for cases where you may want to modify and create your own versions of packages
#     for testing. Defaults to the value of the override_repos fact.
#
#   [env_repositories] Apt repositories which is required per environment , like AT, prod, staging etc.
#
class rjil::system::apt (
  $enable_puppetlabs = true,
  $proxy             = false,
  $repositories      = {},
  $env_repositories  = {},
  $override_repo     = $::override_repo,
  $keys              = {},
  $additional_repositories = {},
) {

  ## two settings to be overrided here in hiera
  ## apt::purge_sources_list: true, apt::purge_sources_list_d: true
  include ::apt

  ## All package operations should follow apt::source
  Apt::Source<||> {
    tag => 'package',
  }
  Apt::Pin<||> {
    tag => 'package',
  }
  Apt::Source<||> -> Package<||>
  Apt::Pin<||> -> Package<||>

  if $enable_puppetlabs {
    include puppet::repo::puppetlabs
  }

  $res_env_repositories = deep_merge($env_repositories, $additional_repositories)

  if ($override_repo) {
    file { ['/var/lib/jiocloud', '/var/lib/jiocloud/overrides']:
      ensure => directory,
      tag    => 'package',
    }
    archive { '/var/lib/jiocloud/overrides/repo.tgz':
      source       => $override_repo,
      extract      => true,
      extract_path => '/var/lib/jiocloud/overrides',
      tag          => 'package',
      creates      => '/var/lib/jiocloud/overrides/Packages',
      before       => Apt::Source['overrides'],
    }
    # pin local repos to have the highest priority
    apt::pin { 'local_repos':
      priority => '999',
      origin   => '""',
    }
    apt::source { 'overrides':
      location       => 'file:/var/lib/jiocloud/overrides',
      release        => './',
      repos          => '',
      include_src    => false,
      trusted_source => true,
    }
  }

  if ($proxy) {
    file { '/etc/apt/apt.conf.d/90proxy':
      content => "Acquire::Http::Proxy \"${proxy}\";",
      owner => 'root',
      group => 'root',
      mode  => '0644',
      tag   => 'package',
    }
  } else {
    file { '/etc/apt/apt.conf.d/90proxy':
      ensure => 'absent',
      tag   => 'package',
    }
  }

  package { 'ubuntu-cloud-keyring':
    ensure => 'present'
  }

  create_resources(apt::key, $keys, {require => Package['ubuntu-cloud-keyring']} )
  create_resources(apt::source, $repositories, {'tag' => 'package'} )
  create_resources(apt::source, $res_env_repositories, {'tag' => 'package'} )
}
