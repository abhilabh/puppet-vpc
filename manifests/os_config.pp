class rjil::os_config(
$package_list = ['python-enum',
      'python-enum34',
      'python-pyasn1',
      'python-mysqldb',
      'python-debtcollector',
      'python-psutil',
      'python-jinja2',
      'python-lxml',
      'python-rfc3986',
      'python-boto',
      'python-neutronclient',
      'python-cinderclient',
      'glance',
      'glance-api',
      'glance-common',
      'glance-registry',
      'nova-api',
      'nova-cert',
      'nova-common',
      'nova-consoleauth',
      'nova-novncproxy',
      'python-glance',
      'python-nova',
      'python-novaclient',
      'python-oslo-log',
      'python-oslo-messaging',
      'python-oslo-rootwrap',
      'python-metricgenerator',
      'python-logbook',
      'nova-conductor',
      'nova-scheduler',
      'python-ec2-api'],
$nova_services= ['nova-api','nova-conductor','nova-scheduler','nova-cert','nova-novncproxy','nova-consoleauth'],
$glance_services= ['glance-api', 'glance-registry'],
){
  user{'glance':
       ensure => present,
  }

  package{$package_list:
          ensure => present,
          require => [User['nova'], User['glance']]
  }

  file{'/etc/nova/nova.conf':
        owner => 'nova',
        group => 'nova',
        source => "puppet:///modules/rjil/nova.conf",
        require => Package['python-nova']
    }

  file{'/etc/nova/api-paste.ini':
        owner => 'nova',
        group => 'nova',
        source => "puppet:///modules/rjil/api-paste.ini",
        require => Package['python-nova']
    }
    
   file{'/etc/nova/policy.json':
        owner => 'nova',
        group => 'nova',
        source => "puppet:///modules/rjil/policy.json",
        require => Package['python-nova']
    }

     file{'/etc/glance/glance-api.conf':
        owner => 'glance',
        group => 'glance',
        source => "puppet:///modules/rjil/glance-api.conf",
        require => Package['python-glance']
    }
    
    file{'/etc/glance/glance-registry.conf':
        owner => 'glance',
        group => 'glance',
        source => "puppet:///modules/rjil/glance-registry.conf",
        require => Package['python-glance']
    } 

    file{'/etc/glance/glance-api-paste.ini':
        owner => 'glance',
        group => 'glance',
        source => "puppet:///modules/rjil/glance-api-paste.ini",
        require => Package['python-glance']
    } 
    
      
    file{'/etc/glance/glance-registry-paste.ini':
        owner => 'glance',
        group => 'glance',
        source => "puppet:///modules/rjil/glance-registry-paste.ini",
        require => Package['python-glance']
    }

    file{'/etc/ec2api/ec2api.conf':
        source => "puppet:///modules/rjil/ec2api.conf",
        require => Package['python-ec2-api']
    }

    file{'/etc/ec2api/api-paste.ini':
        source => "puppet:///modules/rjil/ec2api-api-paste.ini",
        require => Package['python-ec2-api']
    }

   file{'/etc/ec2api/mapping.json':
        source => "puppet:///modules/rjil/ec2api-mapping.json",
        require => Package['python-ec2-api']
    }
  
 

  service{$nova_services:
          ensure=> running,
          require => [File['/etc/nova/nova.conf'], File['/etc/nova/api-paste.ini'], File['/etc/nova/policy.json'], Exec['nova-manage db sync']]
        }

   service{$glance_services:
          ensure=> running,
          require => [File['/etc/glance/glance-api.conf'], File['/etc/glance/glance-api-paste.ini'], File['/etc/glance/glance-registry.conf'], File['/etc/glance/glance-registry-paste.ini'], Exec['glance-manage db sync']]
        }
 
  exec{'ec2-api':
          require => [File['/etc/ec2api/ec2api.conf'], File['/etc/ec2api/api-paste.ini'], File['/etc/ec2api/mapping.json']]
        }


}  
