#
# Class: rjil::neutron::contrail
#

# [* public_subnets *]
#   is a hash of subnetlogicalname => cidr
#   e.g { pub_subnet1 => '100.1.0.0/16'}

# NOTE: Public network will be created on services tenant. In order to specify
# specific tenant name on which public network created, keystone.conf required
# on neutron server which is not the case as of now.

class rjil::neutron::contrail(
  $keystone_admin_user,
  $keystone_admin_password,
  $fip_pools           = {},
  $contrail_api_server = 'lb.neutron.service.consul',
  $rt_number           = 10000,
  $router_asn          = 64512,
  $seed                = false,
  $tenants             = undef,
  $new_iam             = false,
  $ec2_db              = false,
) {

  include ::rjil::neutron

  ##
  # Database connection is not required for contrail
  # if ec2_db not configured to access by neutron we need not
  # have its entry
  ##

  unless $ec2_db {
    Neutron_config<| title == 'database/connection' |> {
      ensure => absent
    }
  }


  ##
  # Subscribe neutron-server to contrailplugin.ini
  ##
  file { '/etc/default/neutron-server':
    content => 'NEUTRON_PLUGIN_CONFIG="/etc/neutron/plugins/opencontrail/ContrailPlugin.ini"',
    require => File['/etc/neutron/plugins/opencontrail/ContrailPlugin.ini'],
    notify  => Service['neutron-server'],
  }

  include rjil::contrail::server

  ##
  # Create default network and fip pools including creation of network, subnet, fip pool etc
  ##
  if $seed {
     #create_resources(rjil::neutron::default_network,$tenants)
     $fip_pool_defaults = {
                          keystone_admin_user     => $keystone_admin_user,
                          keystone_admin_password => $keystone_admin_password,
                          contrail_api_server     => $contrail_api_server,
                          router_asn              => $router_asn,
                        }
     if $new_iam {
       create_resources(rjil::neutron::contrail::new_iam_fip_pool,$fip_pools,$fip_pool_defaults)
     }
     else
     {
       create_resources(rjil::neutron::contrail::fip_pool,$fip_pools,$fip_pool_defaults)
     }
  }
}
