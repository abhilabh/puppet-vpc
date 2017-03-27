class rjil::omd_client (
  $check_mk_version = '1.2.6p12-1',
  $download_source  = 'http://10.140.214.61/apt/vpcjiocloud/vpcbase/pool/main/c/check-mk-agent/',
) {
  class { '::omd::client':
    check_mk_version => $check_mk_version,
    download_source  => $download_source,
  }
}
