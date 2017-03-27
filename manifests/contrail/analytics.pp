###
## Class: rjil::contrail
## Class for deploying contrail analytics
###
class rjil::contrail::analytics (
  $api_virtual_ip       = join(values(service_discover_consul('pre-haproxy')),""),
  $discovery_virtual_ip = join(values(service_discover_consul('pre-haproxy')),""),
  $analytics_flow_ttl   = '48',
  $cassandra_ip_list    = sort(values(service_discover_consul('cassandra-analytics'))),
  $cassandra_seed_hostname = 'vpc-analytics1',
  $cassandra_seeds      = values(service_discover_consul('cassandra-analytics', 'seed')),
  $cassandra_cluster    = 'analytics',
) {


  if $::hostname == $cassandra_seed_hostname {
    $cassandra_seed = true
    notify {'Seed node for cassandra' :}
  } else {
    $cassandra_seed = false
    notify {'Not a seed for cassandra' :}
  }     

  class {'rjil::cassandra': 
    seed           => $cassandra_seed,
    db_for_config  => false,
    cluster_name   => $cassandra_cluster,
    seeds          => $cassandra_seeds,

}


  anchor{'contrail_dep_apps':}
  Service<| title == 'cassandra' |>       ~> Anchor['contrail_dep_apps']

  Anchor['contrail_dep_apps'] -> Service['contrail-analytics-api']
  Anchor['contrail_dep_apps'] -> Service['contrail-collector']
  Anchor['contrail_dep_apps'] -> Service['contrail-query-engine']

  class{'::contrail':
    enable_analytics     => true,
    enable_config        => false,
    enable_control       => false,
    enable_webui         => false,
    enable_ifmap         => false,
    enable_dns           => false,
    api_virtual_ip       => $api_virtual_ip,
    discovery_virtual_ip => $discovery_virtual_ip,
    analytics_flow_ttl   => $analytics_flow_ttl,
    cassandra_ip_list    => $cassandra_ip_list,

  }

}
