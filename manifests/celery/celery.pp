

class rjil::celery::celery (
  $host_zkid_map = {'vpc-analytics1'=>1, 'vpc-analytics2'=>2, 'vpc-analytics3'=>3},
  $analytics_query_endpoint = 'http://localhost:8081/analytics/query',
  $dss_account_id = undef,
  $jcs_access_key = undef,
  $jcs_secret_key = undef,
  $jcs_vpc_endpoint = undef,
  $jcs_dss_endpoint = undef,
  $jcs_iam_endpoint = undef,
  $time_interval = 2400,
  $time_delta = 1200,
  $worker_user = 'celery_worker',
  $periodic_task_interval = 300,
  $broker_url = 'amqp://rabbit:rabbit@127.0.0.1//',
  $flowlog_logfile = '/var/log/flowlogd/flowlog.log',
  $flowlog_configfile = '/etc/flowlogd/flowlogd.cfg',
) {

  class {'rjil::rabbitmq':
    cluster_nodes => keys(service_discover_consul('pre-celery-rabbitmq')),
    consul_service_name => 'celery-rabbitmq',
  }

  class {'rjil::zookeeper':
    hosts => service_discover_consul('pre-celery-zookeeper'),
    consul_service_name => 'celery-zookeeper',
    host_zkid_map => $host_zkid_map,
  }

  anchor{'celery_dep_apps':}
  Service<| title == 'zookeeper' |>       ~> Anchor['celery_dep_apps']
  Service<| title == 'rabbitmq-server' |> ~> Anchor['celery_dep_apps']

  Anchor['celery_dep_apps'] -> Service['celery_worker']
  Anchor['celery_dep_apps'] -> Service['celery_beat']

  $packages = [
  'python-celery',
  'python-zkcelery',
  'python-vine',
  'python-jcsclient',
  'python-flowlogd',
  'python-vpccrypto',
  ]

  package { $packages:
    ensure => present,
  }

  $dep_packages = [
  Package['python-celery'],
  Package['python-vine'],
  Package['python-zkcelery'],
  Package['python-jcsclient'],
  Package['python-flowlogd'],
  Package['python-vpccrypto'],
  ]

  group { $worker_user:
    ensure => present,
  }

  user { $worker_user:
    ensure  => present,
    gid     => $worker_user,
    require => Group[$worker_user],
  }

  file { '/var/log/flowlogd':
    ensure => directory
  }

  file { $flowlog_logfile:
    ensure  => present,
    owner   => $worker_user,
    group   => $worker_user,
    mode    => '0600',
    require => [User[$worker_user],
  Package['python-flowlogd'],
  File['/var/log/flowlogd']],
  }

  rjil::jiocloud::logrotate { 'flowlogd':
    logfile => $flowlog_logfile,
    copytruncate => true,
  }

  rjil::jiocloud::logrotate { 'celery_worker':
    logfile => '/var/log/celery/celery_worker.log',
    copytruncate => true,
  }

  rjil::jiocloud::logrotate { 'celery_beat':
    logfile => '/var/log/celery/celery_beat.log',
    copytruncate => true,
  }

  $zookeeper_hosts = sort(values(service_discover_consul('celery-zookeeper')))
  $zookeeper_port = 2181
  file { $flowlog_configfile:
    owner   => 'root',
    group   => 'root',
    content => template('rjil/flowlogd_config.erb'),
    require => [Package['python-flowlogd']],
    notify  => [Service['celery_worker'], Service['celery_beat']]
  }

  file { '/etc/init.d/celery_worker':
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template('rjil/celery_worker_init.erb'),
    require => $dep_packages
  }

  file { '/etc/init.d/celery_beat':
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template('rjil/celery_beat_init.erb'),
    require => $dep_packages
  }

  service{'celery_worker':
      ensure  => running,
      require => [File['/etc/init.d/celery_worker'],
    File[$flowlog_logfile]]
  }

  service{'celery_beat':
      ensure  => running,
      require => [File['/etc/init.d/celery_worker'],
                File[$flowlog_logfile]]
  }

}
