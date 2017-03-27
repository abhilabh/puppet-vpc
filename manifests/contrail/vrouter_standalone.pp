###
# Class: rjil::contrail::vrouter_standalone
#
###

class rjil::contrail::vrouter_standalone (
  $discovery_address = join(service_discover_dns('lb.neutron.service.consul','name')),
  $api_address       = undef,
  $vrouter_physical_interface = 'eth1',
  $vrouter_physical_interface_backup = undef,
  $vrouter_physical_interface_quanta = undef,
) {

  #include rjil::jiocloud
  include rjil::default_manifest
  include rjil::system::apt
  #include rjil::test::base

  class {'::contrail::vrouter':
    discovery_address => $discovery_address,
    api_address       => $api_address,
    vrouter_physical_interface => $vrouter_physical_interface,
    vrouter_physical_interface_backup => $vrouter_physical_interface_backup,
    vrouter_physical_interface_quanta => $vrouter_physical_interface_quanta,
  }


}
