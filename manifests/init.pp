# == Class: redis
#
# Install and configure a Redis server
#
# === Parameters
#
# All the redis.conf parameters can be passed to the class.
# See below for a complete list of parameters accepted.
#
# Check the README.md file for any further information about parameters for this class.
#
# === Examples
#
#  class { redis:
#    conf_port => '6380',
#    conf_bind => '0.0.0.0',
#  }
#
# === Authors
#
# Felipe Salum <fsalum@gmail.com>
#
# === Copyright
#
# Copyright 2013 Felipe Salum, unless otherwise noted.
#
class redis (
  $package_ensure                   = 'present',
  $service_ensure                   = 'running',
  $service_enable                   = true,
  $service_restart                  = true,
  $conf_daemonize                   = 'yes',
  $conf_pidfile                     = 'UNSET',
  $conf_port                        = '6379',
  $conf_bind                        = '127.0.0.1',
  $conf_timeout                     = '0',
  $conf_tcp_keepalive               = '0',
  $conf_loglevel                    = 'notice',
  $conf_logfile                     = 'UNSET',
  $conf_syslog_enabled              = 'UNSET',
  $conf_syslog_ident                = 'UNSET',
  $conf_syslog_facility             = 'UNSET',
  $conf_databases                   = '16',
  $conf_save                        = 'UNSET',
  $conf_nosave                      = 'UNSET',
  $conf_stop_writes_on_bgsave_error = 'yes',
  $conf_rdbcompression              = 'yes',
  $conf_rdbchecksum                 = 'yes',
  $conf_dbfilename                  = 'dump.rdb',
  $conf_dir                         = '/var/lib/redis/',
  $conf_slaveof                     = 'UNSET',
  $conf_masterauth                  = 'UNSET',
  $conf_slave_server_stale_data     = 'yes',
  $conf_slave_read_only             = 'yes',
  $conf_repl_ping_slave_period      = '10',
  $conf_repl_timeout                = '60',
  $conf_repl_disable_tcp_nodelay    = 'no',
  $conf_slave_priority              = '100',
  $conf_requirepass                 = 'UNSET',
  $conf_maxclients                  = 'UNSET',
  $conf_maxmemory                   = 'UNSET',
  $conf_maxmemory_policy            = 'UNSET',
  $conf_maxmemory_samples           = 'UNSET',
  $conf_appendonly                  = 'no',
  $conf_appendfilename              = 'UNSET',
  $conf_appendfsync                 = 'everysec',
  $conf_no_appendfsync_on_rewrite   = 'no',
  $conf_auto_aof_rewrite_percentage = '100',
  $conf_auto_aof_rewrite_min_size   = '64mb',
  $conf_lua_time_limit              = '5000',
  $conf_slowlog_log_slower_than     = '10000',
  $conf_slowlog_max_len             = '1024',
  $conf_vm_enabled                  = 'no',
  $conf_vm_swap_file                = '/tmp/redis.swap',
  $conf_vm_max_memory               = '0',
  $conf_vm_page_size                = '32',
  $conf_vm_pages                    = '134217728',
  $conf_vm_max_threads              = '4',
  $conf_hash_max_zipmap_entries     = '512',
  $conf_hash_max_zipmap_value       = '64',
  $conf_list_max_ziplist_entries    = '512',
  $conf_list_max_ziplist_value      = '64',
  $conf_set_max_intset_entries      = '512',
  $conf_zset_max_ziplist_entries    = '128',
  $conf_zset_max_ziplist_value      = '64',
  $conf_activerehashing             = 'yes',
  $conf_client_output_buffer_limit_normal = '0 0 0',
  $conf_client_output_buffer_limit_slave  = '256mb 64mb 60',
  $conf_client_output_buffer_limit_pubsub = '32mb 8mb 60',
  $conf_hz                          = '10',
  $conf_aof_rewrite_incremental_fsync = 'yes',
  $conf_include                     = 'UNSET',
  $conf_glueoutputbuf               = 'yes',
) {

  include redis::params

  $version_family = $package_ensure ? {
    /2\.8\..*/ => '2.8',
    /2\.6\..*/ => '2.6',
    default    => $redis::params::version_family
  }

  $conf_template  = $redis::params::conf_template
  $conf_redis     = $redis::params::conf
  $conf_logrotate = $redis::params::conf_logrotate
  $service        = $redis::params::service

  if $package_name {
    $package     = $package_name
  }else{
    $package      = $redis::params::package
  }

  if $conf_pidfile {
    $conf_pidfile_real = $conf_pidfile
  }else{
    $conf_pidfile_real = $::redis::params::pidfile
  }

  if $conf_logfile {
    $conf_logfile_real = $conf_logfile
  }else{
    $conf_logfile_real = $::redis::params::logfile
  }

  if $version_family == '2.8' {
    $redis_tmp_directory = "/tmp/redis-${package_ensure}"
    $redis_download_url = "http://download.redis.io/releases/redis-2.8.13.tar.gz"

    file { "rediss::install::dir":   
      ensure => directory,     
      path   => $redis_tmp_directory, 
      before => Anchor["redis::install::dir::anchor"]
    }

    anchor { "redis::install::dir::anchor":
      before => Exec["redis::install::download::extract"],
    }
    
    exec { "redis::install::download::extract":
      command => "wget -O - ${redis_download_url} | tar xz",
      cwd     => $redis_tmp_directory,
      require => File[$redis_tmp_directory],
      path    => $::path,
    }

    exec { "redis::install::make::install":
      command => "make && make install",
      cwd     => "${redis_tmp_directory}/redis-${package_ensure}",
      path    => $::path,
      require => Exec["redis::install::download::extract"],
    }

    exec { "redis::install::update::init.d":
      command => "sed -i 's/sbin/local\/bin/g' /etc/init.d/redis",
      user    => 'root',
      group   => 'root',
      path    => $::path,
      require => Exec["redis::install::make::install"],
    }

    exec { "redis::install::restart":
      command => "/etc/init.d/redis restart",
      path    => $::path,
      require => Exec["redis::install::update::init.d"]
    }

    package { 'redis':
      name => $package
    }

  } else {
    exec { "redis::package::update::init.d":
      command => "sed -i 's/sbin/local\/bin/g' /etc/init.d/redis",
      user    => 'root',
      group   => 'root',
      path    => $::path,
    }

    package { 'redis':
      ensure => $package_ensure,
      name   => $package,
    }
  }

  service { 'redis':
    ensure     => $service_ensure,
    name       => $service,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [ Package['redis'],
                    Exec[$conf_dir],
                    File[$conf_redis] ],
  }

  file { $conf_redis:
    path    => $conf_redis,
    content => template("redis/${conf_template}"),
    owner   => root,
    group   => root,
    mode    => '0644',
    require => Package['redis'],
  }

  file { $conf_logrotate:
    path    => $conf_logrotate,
    content => template('redis/redis.logrotate.erb'),
    owner   => root,
    group   => root,
    mode    => '0644',
  }

  exec { $conf_dir:
    path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    command => "mkdir -p ${conf_dir}",
    user    => root,
    group   => root,
    creates => $conf_dir,
    before  => Service['redis'],
    require => Package['redis'],
  }

  file { $conf_dir:
    ensure  => directory,
    owner   => redis,
    group   => redis,
    mode    => '0755',
    before  => Service['redis'],
    require => Exec[$conf_dir],
  }

  if $service_restart == true {
    Exec[$conf_dir] ~> Service['redis']
    File[$conf_redis] ~> Service['redis']
  }

}
