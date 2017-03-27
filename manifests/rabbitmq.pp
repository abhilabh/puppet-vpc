#
# Class: rjil::rabbitmq
#  This class to manage contrail rabbitmq dependency
#
# == Hiera elements required
#
# rabbitmq::manage_repo: no
#   This parameter to disable apt repo management in rabbitmq module
#
# rabbitmq::admin::enable: no
#   To disable rabbitmqadmin
#   Note: In original contrail installation it is disabled, so starting with
#   disabling it.
#


class rjil::rabbitmq (
  $config_cluster = true,
  $rabbit_admin_user = undef,
  $rabbit_admin_pass = undef,
  $cluster_nodes = keys(service_discover_consul('pre-rabbitmq')),
  $erlang_cookie = 'A_SECRET_COOKIE',
  $cluster_node_type = 'disc',
  $min_members = '3',
  $consul_service_name = 'rabbitmq',
) {

  rjil::test { 'check_rabbitmq.sh': }

  # forward non-seed failures when there is no leader in their cluster list
  if size($cluster_nodes) < $min_members {
    $fail = true
  } else {
    $fail = false
  }

  runtime_fail { 'rabbitmq_not_ready':
    fail    => $fail,
    message => "Waiting for ${min_members} rabbitmq members",
  }

  class {'::rabbitmq': 
    config_cluster => $config_cluster,
    cluster_nodes => $cluster_nodes,
    erlang_cookie => $erlang_cookie,
    wipe_db_on_cookie_change => true,
    cluster_node_type => $cluster_node_type,
    require => Runtime_fail['rabbitmq_not_ready']
 }

  rabbitmq_user { $rabbit_admin_user:
    admin    => true,
    password => $rabbit_admin_pass,
  }

  # Add a check that always succeeds that we can use to know
  # when we have enough members ready to configure a cluster.
  rjil::jiocloud::consul::service { "pre-$consul_service_name":
    check_command => '/bin/true',
    tags => ['real', 'contrail']
  }

  rabbitmq_user_permissions { "${rabbit_admin_user}@/":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }

 rjil::test::check { $consul_service_name:
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 5672,
  }

  rjil::jiocloud::consul::service { $consul_service_name:
    tags          => ['real', 'contrail'],
    port          => 5672,
  }


}
