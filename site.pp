Exec {
  path      => ["/bin/", "/sbin/", "/usr/bin/", "/usr/sbin/", "/usr/local/bin/", "/usr/local/sbin/"],
  logoutput => true
}

node /^vpc-service\d+/ {
  include rjil::base
  include rjil::haproxy
  include rjil::haproxy::contrail
  include rjil::omd_client
  include rjil::monitoring::base
  include rjil::monitoring::vpcservice
  include rjil::pacemaker
}

node /^vpc-cfg\d+/{
  include rjil::base
  include rjil::redis
  include rjil::cassandra
  include rjil::rabbitmq
  include rjil::zookeeper
  include rjil::contrail::server
  include rjil::neutron::contrail
  include rjil::omd_client
  include rjil::monitoring::base
  include rjil::monitoring::vpccfg
}



node /^vpc-ctrl\d+/ {
  include rjil::base
  include rjil::redis
  include rjil::cassandra
  include rjil::rabbitmq
  include rjil::zookeeper
  include rjil::contrail::server
  include rjil::neutron::contrail
  include rjil::omd_client
  include rjil::monitoring::base
  include rjil::monitoring::vpcctrl
}



node /^cp\d+/ {
  include rjil::contrail::vrouter_standalone
  include rjil::omd_client
  include rjil::monitoring::cp
}

node /^prod-cp\d+/ {
  include rjil::contrail::vrouter_standalone
  include rjil::omd_client
  include rjil::monitoring::cp
}

node /^vpc-aws\d+/ {
  include rjil::base
  include rjil::contrail::ec2api
  include rjil::omd_client
}
# VPC spare nodes will be utilized in staging environment for testing mixed services of contrail
# For now this will used for deploying standalone vrouter

node /^vpc-spare\d+/ { 
  include rjil::contrail::vrouter_standalone
}

#Adding CP nodes for full integration testing

node /^vpc-cp\d+/ {
  include rjil::base
  include openstack_extras::client
  include rjil::contrail::vrouter
  include rjil::openstack_zeromq
  include rjil::nova::compute
}

#Adding St nodes for all testing the complete setup

node /^st\d+/ {
  include rjil::base
  include rjil::ceph
  include rjil::ceph::mon_config
  include rjil::ceph::osd
  ensure_resource('rjil::service_blocker', 'stmon', {})
  Class['rjil::base'] -> Rjil::Service_blocker['stmon'] ->
  Class['rjil::ceph::osd']
}

##
# single leader that will be used to ensure that all mons form a single cluster.
#
# The only difference in stmon and stmonleader is that stmonleader is the node
# which starts first in the ceph cluster initialization. After that, both
# those roles will serve the same purpose.
# All ceph servers and clients (st, stmon, cp, oc nodes) except stmonleader will wait for at least
# one "stmon" service node in consul.
#
# The leader will register the service in consul with name "stmon" (or
# any other name if overridden in hiera).
#
##

node /^stmonleader1/ {
  include rjil::base
  include rjil::ceph
  include rjil::ceph::mon
  include rjil::ceph::osd
  include rjil::ceph::radosgw

  rjil::jiocloud::consul::service { 'stmonleader':
    port          => 6789,
    check_command => '/usr/lib/jiocloud/tests/check_ceph_mon.sh'
  }
}

##
# setup ceph osd and mon configuration on ceph Mon nodes.
# All ceph mon nodes are registered in consul as service name "stmon" (or any
# other name if overridden)
#
# stmon nodes will wait at least one "stmon" service to be up in consul before
# initialize themselves
##

node /^stmon\d+/ {
  include rjil::base
  include rjil::ceph
  include rjil::ceph::mon
  include rjil::ceph::osd
  include rjil::ceph::radosgw
  ensure_resource('rjil::service_blocker', 'stmonleader', {
  }
  )
  Class[rjil::base] -> Rjil::Service_blocker['stmonleader']
  Rjil::Service_blocker['stmonleader'] -> Class['rjil::ceph::mon::mon_config']
}

#Complete HAPROXY for testing
node /^haproxy\d+/ {
  include rjil::base
  include rjil::haproxy
  include rjil::haproxy::contrail
  include rjil::contrail::ec2api
  include rjil::haproxy::openstack
}

node /^keystone\d+/ {
  include rjil::base
  #include openstack_extras::client
  include rjil::glance
  include rjil::nova::controller
  include rjil::openstack_zeromq
  include rjil::db
}

node /^httpproxy\d+/ {
  include rjil::base
  include rjil::http_proxy
  dnsmasq::conf { 'google':
    ensure  => present,
    content => 'server=8.8.8.8',
  }
  include rjil::jiocloud::vagrant::dhcp
}


node /^vpc-monitor\d+/ {
  include rjil::base
  include rjil::omd_client
  include rjil::omd_server
}



node /^vpc-analytics\d+/ {
  include rjil::base
  include rjil::redis
  include rjil::contrail::analytics
  include rjil::celery::celery
}
