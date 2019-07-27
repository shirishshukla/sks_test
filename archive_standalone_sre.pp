###
# Description: This manifest is to manage standalone-full-ha.xml file
###
class jboss::archive_standalone_sre (
  $security_realms_properties_path    = $jboss::security_realms_properties_path,
  $security_realms_relative_to        = $jboss::security_realms_relative_to,
) {

  $install_type = "$jboss::install_type"
  case $install_type {
     'eap7':  { 
                 $subsystem_xmlns   =  $subsystem_xmlns_eap7
                 $deployments_entry = $deployments_entry_eap7
               }
     'jboss': { 
                 $subsystem_xmlns   =  $subsystem_xmlns_jboss
                 $deployments_entry = $deployments_entry_jboss
             }
     'default': { fail("Please provide  install type jboss or eap7") }
  }

  Exec { path  => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' }
  File {  mode => '0755', owner => $jboss::user, group => $jboss::group }

  $config_path                      = "${jboss::install_path}/${jboss::app_module}/configuration"
  $dep_valid                        = "$config_path/dep_valid"
  $standalone_full_ha_file          = "${config_path}/standalone-full-ha.xml"
  $standalone_full_ha_prime_source  = "$dep_valid/standalone-full-ha_prime_source.xml"
  
  ## mod_cluster_config
  $advertise_socket = "$jboss::archive_standalone_sre::mod_cluster_config::advertise_socket"
  $proxies          = "$jboss::archive_standalone_sre::mod_cluster_config::proxies"
  $balancer         = "$jboss::archive_standalone_sre::mod_cluster_config::balancer"
  $connector        = "$jboss::archive_standalone_sre::mod_cluster_config::connector"
  $load_metric_type = "$jboss::archive_standalone_sre::mod_cluster_config::load_metric_type"
  $proxy_host1      = "$jboss::archive_standalone_sre::mod_cluster_config::proxy_host1"
  $proxy_port1      = "$jboss::archive_standalone_sre::mod_cluster_config::proxy_port1"
  $proxy_host2      = "$jboss::archive_standalone_sre::mod_cluster_config::proxy_host2"
  $proxy_port2      = "$jboss::archive_standalone_sre::mod_cluster_config::proxy_port2"
  $proxy_host3      = "$jboss::archive_standalone_sre::mod_cluster_config::proxy_host3"
  $proxy_port3      = "$jboss::archive_standalone_sre::mod_cluster_config::proxy_port3"
  $proxy_host4      = "$jboss::archive_standalone_sre::mod_cluster_config::proxy_host4"
  $proxy_port4      = "$jboss::archive_standalone_sre::mod_cluster_config::proxy_port4"
  
  # This is to create standalone-full-ha_prime_source.xml file based on pre-defined template
  file { $standalone_full_ha_prime_source:
    content   => template("${module_name}/sre-standalone-full-ha_prime_source.xml.erb"),
    notify    => Exec["Create $standalone_full_ha_file"],
  }

  # 
  exec { "Create $standalone_full_ha_file":
    command     => "/usr/bin/cp -rp $config_path/dep_valid/standalone-full-ha_prime_source.xml $config_path/standalone-full-ha.xml",
    refreshonly => true,
  }

  # Multiple File_Line resources to Pass values from console and maintain standalone-full-ha.xml
  file_line { "standalone-full-ha.xml security-realms-properties":
    ensure             => present,
    path               => "${jboss::install_path}/${jboss::app_module}/configuration/standalone-full-ha.xml",
    line               => "                    <properties path=\"${security_realms_properties_path}\" relative-to=\"${security_realms_relative_to}\"/>",
    match              => '<properties path="mgmt-users.properties" relative-to="jboss.server.config.dir"/>',
    require            => File[$standalone_full_ha_prime_source],
    append_on_no_match => false,
  }

 # This is to copy standalone-full-ha.xml_updates.sh script to node dep_valid folder:
  file { "${jboss::install_path}/${jboss::app_module}/configuration/dep_valid/standalone-full-ha.xml_updates.sh":
    ensure   => file,
    source   => "puppet:///modules/${module_name}/standalone-full-ha.xml_updates.sh",
    require  => File["${jboss::install_path}/${jboss::app_module}/configuration/dep_valid/standalone-full-ha_prime_source.xml"]
  }

}
## END

####
# Description: 
####
class jboss::archive_standalone_sre::mod_cluster_config(
$advertise_socket = "modcluster",
$proxies          = "proxy-one proxy-two",
$balancer         = "srecluster",
$connector        = "https",
$load_metric_type = "cpu"
$proxy_host1      = "dhwsrewebd1",
$proxy_port1      = "6666",
$proxy_host2      = "dhwsrewebd2",
$proxy_port2      = "6666",
$proxy_host3      = "dhwsrewebd3",
$proxy_port3      = "6666",
$proxy_host4      = "dhwsrewebd4",
$proxy_port4      = "6666",
){
  
  ## 
}

#This calss is to Create a datasource tag in standalone-full-ha.xml File
#This Run's the standalone-full-ha.xml_updates.sh script,remotly
class jboss::archive_standalone_sre::datasource00(
  $jta = true,
  $jndi_name = undef,
  $pool_name = undef,
  $enabled = true,
  $use_ccm = true,
  $statistics_enabled = false,
  $connection_url = undef,
  $driver_class = 'oracle.jdbc.OracleDriver',
  $driver = 'dhw.com.oracle',
  $min_pool_size = 25,
  $max_pool_size = 100,
  $security_domain = undef,
  $validation_class_name = 'org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker',
  $check_valid_connection_sql = 'SELECT 1 FROM DUAL',
  $validate_on_match = true,
  $background_validation = false,
  $background_validation_millis = 100,
  $exception_sorter_class_name = 'org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter',
  $set_tx_query_timeout = false,
  $blocking_timeout_millis = 0,
  $idle_timeout_minutes = 5,
  $query_timeout = 0,
  $use_try_lock = 0,
  $allocation_retry = 0,
  $allocation_retry_wait_millis = 0,
  $share_prepared_statements = false,
  $username = 'IWS_SIMULATOR_USER',
  $password = undef,
) {

  if $jndi_name and $pool_name and $connection_url and $driver_class and $driver and $security_domain and $validation_class_name and $check_valid_connection_sql and $exception_sorter_class_name and $username and $password {

  $toFile = "${jboss::install_path}/${jboss::app_module}/configuration/standalone-full-ha.xml"

  $cmd = "sh ${jboss::install_path}/${jboss::app_module}/configuration/dep_valid/standalone-full-ha.xml_updates.sh \'${toFile}\' \'${jta}\' \'${jndi_name}\' \'${pool_name}\' \'${enabled}\' \'${use_ccm}\' \'${statistics_enabled}\' \'${connection_url}\' \'${driver_class}\' \'${driver}\' \'${min_pool_size}\' \'${max_pool_size}\' \'${security_domain}\' \'${validation_class_name}\' \'${check_valid_connection_sql}\' \'${validate_on_match}\' \'${background_validation}\' \'${background_validation_millis}\' \'${exception_sorter_class_name}\' \'${set_tx_query_timeout}\' \'${blocking_timeout_millis}\' \'${idle_timeout_minutes}\' \'${query_timeout}\' \'${use_try_lock}\' \'${allocation_retry}\' \'${allocation_retry_wait_millis}\' \'${share_prepared_statements}\' \'${username}\' \'${password}\'"

  Exec { path => ['/bin/', '/sbin', '/usr/bin/', '/usr/sbin/'] }
  $dcname = $name.split(':')[-1]
  $dep_validpth = "${jboss::install_path}/${jboss::app_module}/configuration/dep_valid"

  file { "$dep_validpth/$dcname.status":
    ensure  => present, 
    content => $cmd,
    notify  => Exec["Add $name"],
  }

  exec { "Add $name":
    command     => "echo \"<!-- $name -->\" >> $dep_validpth/standalone-full-ha_prime_source.xml",
    refreshonly => true,
    notify      => [ File["$dep_validpth/standalone-full-ha_prime_source.xml"], Exec[$cmd] ]
  }

  exec { $cmd:
    refreshonly => true,
    #unless  => "grep -i \"datasource.*.jndi-name.*.${jndi_name}.*\" $toFile",
    require     => File["$dep_validpth/standalone-full-ha.xml_updates.sh"],
  }
} else {
  fail("Please provide all variables.")
}
}

## END ##

#This Run's the standalone-full-ha.xml_updates.sh script,remotly
class jboss::archive_standalone_sre::datasource01(
$jta = true,
$jndi_name = undef,
$pool_name = undef,
$enabled = true,
$use_ccm = true,
$statistics_enabled = false,
$connection_url = undef,
$driver_class = 'oracle.jdbc.OracleDriver',
$driver = 'dhw.com.oracle',
$min_pool_size = 25,
$max_pool_size = 100,
$security_domain = undef,
$validation_class_name = 'org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker',
$check_valid_connection_sql = 'SELECT 1 FROM DUAL',
$validate_on_match = true,
$background_validation = false,
$background_validation_millis = 100,
$exception_sorter_class_name = 'org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter',
$set_tx_query_timeout = false,
$blocking_timeout_millis = 0,
$idle_timeout_minutes = 5,
$query_timeout = 0,
$use_try_lock = 0,
$allocation_retry = 0,
$allocation_retry_wait_millis = 0,
$share_prepared_statements = false,
$username = 'IWS_SIMULATOR_USER',
$password = undef,
) {

if $jndi_name and $pool_name and $connection_url and $driver_class and $driver and $security_domain and $validation_class_name and $check_valid_connection_sql and $exception_sorter_class_name and $username and $password {

  $toFile = "${jboss::install_path}/${jboss::app_module}/configuration/standalone-full-ha.xml"

  $cmd = "sh ${jboss::install_path}/${jboss::app_module}/configuration/dep_valid/standalone-full-ha.xml_updates.sh \'${toFile}\' \'${jta}\' \'${jndi_name}\' \'${pool_name}\' \'${enabled}\' \'${use_ccm}\' \'${statistics_enabled}\' \'${connection_url}\' \'${driver_class}\' \'${driver}\' \'${min_pool_size}\' \'${max_pool_size}\' \'${security_domain}\' \'${validation_class_name}\' \'${check_valid_connection_sql}\' \'${validate_on_match}\' \'${background_validation}\' \'${background_validation_millis}\' \'${exception_sorter_class_name}\' \'${set_tx_query_timeout}\' \'${blocking_timeout_millis}\' \'${idle_timeout_minutes}\' \'${query_timeout}\' \'${use_try_lock}\' \'${allocation_retry}\' \'${allocation_retry_wait_millis}\' \'${share_prepared_statements}\' \'${username}\' \'${password}\'"
 
  Exec { path => ['/bin/', '/sbin', '/usr/bin/', '/usr/sbin/'] }
  $dcname = $name.split(':')[-1]
  $dep_validpth = "${jboss::install_path}/${jboss::app_module}/configuration/dep_valid"

  file { "$dep_validpth/$dcname.status":
    ensure  => present, 
    content => $cmd,
    notify  => Exec["Add $name"],
  }

  exec { "Add $name":
    command     => "echo \"<!-- $name -->\" >> $dep_validpth/standalone-full-ha_prime_source.xml",
    refreshonly => true,
    notify      => File["$dep_validpth/standalone-full-ha_prime_source.xml"]
  }

  exec { $cmd:
    unless  => "grep -i \"datasource.*.jndi-name.*.${jndi_name}.*\" $toFile",
    require     => File["$dep_validpth/standalone-full-ha.xml_updates.sh"],
  }
} else {
  fail("Please provide all variables.")
}
}

## END ##

#This calss is to Create a second datasource tag in standalone-full-ha.xml File
#This Run's the standalone-full-ha.xml_updates.sh script,remotly
class jboss::archive_standalone_sre::datasource02(
$jta = true,
$jndi_name = undef,
$pool_name = undef,
$enabled = true,
$use_ccm = true,
$statistics_enabled = false,
$connection_url = undef,
$driver_class = 'oracle.jdbc.OracleDriver',
$driver = 'dhw.com.oracle',
$min_pool_size = 25,
$max_pool_size = 100,
$security_domain = undef,
$validation_class_name = 'org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker',
$check_valid_connection_sql = 'SELECT 1 FROM DUAL',
$validate_on_match = true,
$background_validation = false,
$background_validation_millis = 100,
$exception_sorter_class_name = 'org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter',
$set_tx_query_timeout = false,
$blocking_timeout_millis = 0,
$idle_timeout_minutes = 5,
$query_timeout = 0,
$use_try_lock = 0,
$allocation_retry = 0,
$allocation_retry_wait_millis = 0,
$share_prepared_statements = false,
$username = 'IWS_SIMULATOR_USER',
$password = undef,
) {

if $jndi_name and $pool_name and $connection_url and $driver_class and $driver and $security_domain and $validation_class_name and $check_valid_connection_sql and $exception_sorter_class_name and $username and $password {

  $toFile = "${jboss::install_path}/${jboss::app_module}/configuration/standalone-full-ha.xml"

  $cmd = "sh ${jboss::install_path}/${jboss::app_module}/configuration/dep_valid/standalone-full-ha.xml_updates.sh \'${toFile}\' \'${jta}\' \'${jndi_name}\' \'${pool_name}\' \'${enabled}\' \'${use_ccm}\' \'${statistics_enabled}\' \'${connection_url}\' \'${driver_class}\' \'${driver}\' \'${min_pool_size}\' \'${max_pool_size}\' \'${security_domain}\' \'${validation_class_name}\' \'${check_valid_connection_sql}\' \'${validate_on_match}\' \'${background_validation}\' \'${background_validation_millis}\' \'${exception_sorter_class_name}\' \'${set_tx_query_timeout}\' \'${blocking_timeout_millis}\' \'${idle_timeout_minutes}\' \'${query_timeout}\' \'${use_try_lock}\' \'${allocation_retry}\' \'${allocation_retry_wait_millis}\' \'${share_prepared_statements}\' \'${username}\' \'${password}\'"

  Exec { path => ['/bin/', '/sbin', '/usr/bin/', '/usr/sbin/'] }
  $dcname = $name.split(':')[-1]
  $dep_validpth = "${jboss::install_path}/${jboss::app_module}/configuration/dep_valid"
  file { "$dep_validpth/$dcname.status":
    content    => $cmd,
    notify => Exec["Add $name"],
  }

  exec { "Add $name":
    command     => "echo \"<!-- $name -->\" >> $dep_validpth/standalone-full-ha_prime_source.xml",
    refreshonly => true,
    notify      => File["$dep_validpth/standalone-full-ha_prime_source.xml"]
  }

  exec { $cmd:
   unless  => "grep -i \"datasource.*.jndi-name.*.${jndi_name}.*\" $toFile",
   require => File["$dep_validpth/standalone-full-ha.xml_updates.sh"],
  }
} else {
  fail("Please provide all variables.")
}
}
## END ##