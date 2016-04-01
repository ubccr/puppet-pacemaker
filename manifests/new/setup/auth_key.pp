# == Class: pacemaker::new::setup::aith_key
#
# Install the cluster authencicatio key used to
# secure the Corosync internode communication
# if the key is provided and enabled.
#
# [*auth_key_enabled*]
#   Enable of disable the use of Corosync auth keys.
#   Enabling this will require *cluster_auth_key* to be set too.
#
# [*cluster_auth_key*]
#   The string used to encrypt the Corosync inter-node communications.
#   This should be a string generated by *corosync-keygen* or by any other
#   means. If will placed to the */etc/corosync/authkey* file
#   and will be used to authenticate internode corosync communication.
#   Options *secauth* will be enabled if this key is present.
#
# [*cluster_user*]
#   The systemn user owner of the key files.
#
# [*cluster_group*]
#   The systemn user group of the key files.
#
class pacemaker::new::setup::auth_key (
  $cluster_auth_enabled = $::pacemaker::new::params::cluster_auth_enabled,
  $cluster_auth_key     = $::pacemaker::new::params::cluster_auth_key,
  $cluster_user         = $::pacemaker::new::params::cluster_user,
  $cluster_group        = $::pacemaker::new::params::cluster_group,
) inherits ::pacemaker::new::params {
  validate_bool($cluster_auth_enabled)
  validate_string($cluster_user)
  validate_string($cluster_group)

  if $cluster_auth_enabled {
    $key_ensure = 'present'
  } else {
    $key_ensure = 'absent'
  }

  file { 'corosync-auth-key' :
    ensure  => $key_ensure,
    path    => '/etc/corosync/authkey',
    content => $cluster_auth_key,
    owner   => $cluster_user,
    group   => $cluster_group,
    mode    => '0640',
  }

  file { 'pacemaker-auth-key' :
    ensure => $key_ensure,
    path   => '/etc/pacemaker/authkey',
    target => '/etc/corosync/authkey',
    owner  => $cluster_user,
    group  => $cluster_group,
    mode   => '0640',
  }

  # authkey should be placed before the cluster is created
  File['pacemaker-auth-key'] ->
  Exec <| title == 'create-cluster' |>

  File['corosync-auth-key'] ->
  Exec <| title == 'create-cluster' |>

  File['pacemaker-auth-key'] ~>
  Service <| tag == 'cluster-service' |>

  File['corosync-auth-key'] ~>
  Service <| tag == 'cluster-service' |>
}