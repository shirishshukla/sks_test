###
# Description: This manifest is to manage standalone-full-ha.xml file 
# Using Multiple sub-classes to manage the standalone-full-ha file.
###

class jboss::archive_standalone_sre (
) {

  $install_type = "$jboss::install_type"
  $app_module = "$jboss::app_module"

  case $install_type {
    'eap7':  { 
                $subsystem_xmlns   = $subsystem_xmlns_eap7
                $deployments_entry = $deployments_entry_eap7
            }
    'jboss': { 
                $subsystem_xmlns   =  $subsystem_xmlns_jboss
                $deployments_entry = $deployments_entry_jboss
            }
    'default': { 
	            fail("Please provide  install type jboss or eap7")
            }
  }

  Exec { path  => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' }
  File { mode => '0755', owner => $jboss::user, group => $jboss::group }

  $config_path                      = "${jboss::install_path}/${jboss::app_module}/configuration"
  $dep_valid                        = "${config_path}/dep_valid"
  $standalone_full_ha_file          = "${config_path}/standalone-full-ha.xml"
  $standalone_full_ha_file_back     = "${dep_valid}/standalone-full-ha.xml_back"
  $standalone_full_ha_prime_source  = "${dep_valid}/standalone-full-ha_prime_source.xml"

  ## system-properties
  if $jboss::archive_standalone_sre::system_properties::system_properties_enabled {
    $system_properties_enabled = "$jboss::archive_standalone_sre::system_properties::system_properties_enabled"
    $property_name_1  = "$jboss::archive_standalone_sre::system_properties::property_name_1"
    $value_1          = "$jboss::archive_standalone_sre::system_properties::value_1"
    $property_name_2  = "$jboss::archive_standalone_sre::system_properties::property_name_2"
    $value_2          = "$jboss::archive_standalone_sre::system_properties::value_2"
    $property_name_3  = "$jboss::archive_standalone_sre::system_properties::property_name_3"
    $value_3          = "$jboss::archive_standalone_sre::system_properties::value_3"
  }
  
  ## mod_cluster_config
  if $jboss::archive_standalone_sre::mod_cluster_config::mod_cluster_config_enabled {
    $mod_cluster_config_enabled = "$jboss::archive_standalone_sre::mod_cluster_config::mod_cluster_config_enabled"
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
    $ssl_certificate_key_file   = "$jboss::archive_standalone_sre::mod_cluster_config::ssl_certificate_key_file"
    $ca_certificate_file        = "$jboss::archive_standalone_sre::mod_cluster_config::ca_certificate_file"
  }
  
  ## security_realm_ldapConnection
  if $jboss::archive_standalone_sre::security_realm_ldapConnection::security_realm_ldapconnection_enabled {
    $security_realm_ldapconnection_enabled = "$jboss::archive_standalone_sre::security_realm_ldapConnection::security_realm_ldapconnection_enabled"
    $security_realm_name    = "$jboss::archive_standalone_sre::security_realm_ldapConnection::security_realm_name"
    $base_dn                = "$jboss::archive_standalone_sre::security_realm_ldapConnection::base_dn"
    $recursive              = "$jboss::archive_standalone_sre::security_realm_ldapConnection::recursive"
    $advanced_filter_filter = "$jboss::archive_standalone_sre::security_realm_ldapConnection::advanced_filter_filter"
    $ldap_connection        = "$jboss::archive_standalone_sre::security_realm_ldapConnection::ldap_connection"
    $group_name             = "$jboss::archive_standalone_sre::security_realm_ldapConnection::group_name"
    $iterative              = "$jboss::archive_standalone_sre::security_realm_ldapConnection::group_name"
    $group_dn_attribute     = "$jboss::archive_standalone_sre::security_realm_ldapConnection::group_dn_attribute"
    $group_name_attribute   = "$jboss::archive_standalone_sre::security_realm_ldapConnection::group_name_attribute"
    $group_attribute        = "$jboss::archive_standalone_sre::security_realm_ldapConnection::group_attribute"
  }
  
  ## security_realm_HTTPSRealm
  if $jboss::archive_standalone_sre::security_realm_httpsrealm::security_realm_httpsrealm_enabled {
    $security_realm_httpsrealm_enabled  = "$jboss::archive_standalone_sre::security_realm_httpsrealm::security_realm_httpsrealm_enabled"
    $security_realm_name_https    = "$jboss::archive_standalone_sre::security_realm_httpsrealm::security_realm_name_https"
    $keystore_path                = "$jboss::archive_standalone_sre::security_realm_httpsrealm::keystore_path"
    $https_listener_name          = "$jboss::archive_standalone_sre::security_realm_httpsrealm::https_listener_name"
    $socket_binding               = "$jboss::archive_standalone_sre::security_realm_httpsrealm::socket_binding"
  }
  
  ## Delete standalone-full-ha file, if any manual modifications on file
  exec { 'standalone file compare':
    command  => "test -f ${standalone_full_ha_file_back} && rm -rf ${standalone_full_ha_file} ${standalone_full_ha_prime_source}",
    unless   => "test $(md5sum ${standalone_full_ha_file} | cut -b -32) == $(md5sum ${standalone_full_ha_file_back} | cut -b-32)",
    provider => 'shell',
    notify   => File[$standalone_full_ha_prime_source], Exec['Take backup of $standalone_full_ha_file']
  }

  ## This is to create standalone-full-ha_prime_source.xml file based on pre-defined template
  file { $standalone_full_ha_prime_source:
    content   => template("${module_name}/sre-standalone-full-ha_prime_source.xml.erb"),
    notify    => [ Exec["Create $standalone_full_ha_file"], 
    subscribe => File["${jboss::install_path}/${jboss::app_module}"]
  }

  ## This is to copy the standalone-full-ha_prime_source.xml template to standalone-full-ha.xml
  exec { "Create $standalone_full_ha_file":
    command     => "cp -rp ${standalone_full_ha_prime_source} ${standalone_full_ha_file}",
    refreshonly => true,
  }
   
  ## Take standalone_full_ha_file.xml file backup 
  exec { 'Take backup of $standalone_full_ha_file':
    command  => "cp -rp  ${standalone_full_ha_file} ${standalone_full_ha_file_back}",
    unless   => "test $(md5sum ${standalone_full_ha_file} | cut -b -32) ==  $(md5sum ${standalone_full_ha_file_back} | cut -b -32)",
    provider => 'shell',
  }
 
}
## END main class 


####
# Below class is to manage the system_properties in standalone-full-ha.xml File
####
class jboss::archive_standalone_sre::system_properties(
  Boolean $system_properties_enabled = false,
  $property_name_1    = undef,
  $value_1            = undef,
  $property_name_2    = undef,
  $value_2            = undef,
  $property_name_3    = undef,
  $value_3            = undef
){

}
## END Class 

####
# Below class is to manage the mod_cluster_config in standalone-full-ha.xml File
####
class jboss::archive_standalone_sre::mod_cluster_config(
  Boolean $mod_cluster_config_enabled = false,
  $advertise_socket = "modcluster",
  $proxies          = "proxy-one proxy-two",
  $balancer         = "srecluster",
  $connector        = "https",
  $load_metric_type = "cpu",
  $proxy_host1      = "dhwsrewebd1",
  $proxy_port1      = "6666",
  $proxy_host2      = "dhwsrewebd2",
  $proxy_port2      = "6666",
  $proxy_host3      = undef,
  $proxy_port3      = undef,
  $proxy_host4      = undef,
  $proxy_port4      = undef,
  $ssl_certificate_key_file  = '${jboss.server.config.dir}/dhw.jks',
  $ca_certificate_file       = '${jboss.server.config.dir}/dhw.jks}'
){

}
## END Class 

####
# Below class is to manage the security_realm_ldapconnection in standalone-full-ha.xml File
####
class jboss::archive_standalone_sre::security_realm_ldapconnection(
  Boolean $security_realm_ldapconnection_enabled  = false,
  $security_realm_name    = "LdapConnection",
  $base_dn                = "DC=dhw,DC=state,DC=id,DC=us",
  $recursive              = "true",
  $advanced_filter_filter = "(&amp;(sAMAccountName={0})(|(memberOf=CN=LNXMW,OU=Security Groups,DC=dhw,DC=state,DC=id,DC=us)(memberOf=CN=LNXUSER,OU=Security Groups,DC=dhw,DC=state,DC=id,DC=us)(sAMAccountName=mwsvcibesprod)))",
  $ldap_connection        = "ldap_connection",
  $group_name             = "SIMPLE",
  $iterative              = "false",
  $group_dn_attribute     = "dn",
  $group_name_attribute   = "cn",
  $group_attribute        = "memberOf"
){

}
## END Class 

####
# Below class is to manage the security_realm_httpsrealm in standalone-full-ha.xml File
####
class jboss::archive_standalone_sre::security_realm_httpsrealm(
  Boolean $security_realm_httpsrealm_enabled        = false,
  $security_realm_name_https    = "HTTPSRealm",
  $keystore_path                = '"wild.jks" relative-to="jboss.server.config.dir" keystore-password="changeit" alias="*.dhw.state.id.us"',
  $https_listener_name          = "https_listener_name",
  $socket_binding               = "socket_binding"
){

}
## END Class 

####
# This calss is to Create a datasource tag in standalone-full-ha.xml File
# This Run's the standalone-full-ha.xml_updates.sh script, remotly
####
class jboss::archive_standalone_sre::datasource00(
  Boolean $datasource00_enabled  =  false,
  $jndi_name = undef,
  $pool_name = undef,
  $connection_url = undef,
  $driver = 'dhw.com.oracle',
  $min_pool_size = 25,
  $max_pool_size = 100,
  $security_domain = undef,
  $username = 'IWS_SIMULATOR_USER',
  $password = undef,
){
  
} ## END Class

####
# This calss is to Create a datasource tag in standalone-full-ha.xml File
# This Run's the standalone-full-ha.xml_updates.sh script, remotly
####
class jboss::archive_standalone_sre::datasource01(
  Boolean $datasource01_enabled  =  false,
  $jndi_name = undef,
  $pool_name = undef,
  $connection_url = undef,
  $driver = 'dhw.com.oracle',
  $min_pool_size = 25,
  $max_pool_size = 100,
  $security_domain = undef,
  $username = 'IWS_SIMULATOR_USER',
  $password = undef,
){

} ## END Class

####
# This calss is to Create a datasource tag in standalone-full-ha.xml File
# This Run's the standalone-full-ha.xml_updates.sh script,remotly
####
class jboss::archive_standalone_sre::datasource02(
  Boolean $datasource01_enabled  =  false,
  $jndi_name = undef,
  $pool_name = undef,
  $connection_url = undef,
  $driver = 'dhw.com.oracle',
  $min_pool_size = 25,
  $max_pool_size = 100,
  $security_domain = undef,
  $username = 'IWS_SIMULATOR_USER',
  $password = undef,
){
  
} ## END Class

## END File ##