include ::stdlib
include ::augeas
include ::sysstat
include ::irqbalance
include ::ntp

class { '::timezone': timezone => 'US/Pacific' }
class { '::tuned': profile   => 'virtual-host' }
class { '::selinux': mode => 'disabled' }

if $::osfamily == 'RedHat' {
  if $::operatingsystem != 'Fedora' {
    include ::epel
    Class['epel'] -> Package<| provider != 'rpm' |>
  }

  # kludge around yum-cron install failing without latest yum package:
  # https://bugzilla.redhat.com/show_bug.cgi?id=1293713
  package { 'yum': ensure => latest } -> Package['yum-cron']
  # note:
  #   * el6.x will update everything
  #   * the jenkins package is only present on the master
  class { '::yum_autoupdate':
    exclude      => ['kernel*', 'jenkins'],
    notify_email => false,
    action       => 'apply',
    update_cmd   => 'security',
  }

  # disable postfix on el6/el7 as we don't need an mta
  service { 'postfix':
    ensure => 'stopped',
    enable => false,
  }
}

yumrepo { 'slurm':
  descr    => 'Slurm Packages for Enterprise Linux 7 - $basearch',
  baseurl  => 'http://yum.lsst.codes/slurm/7/x86_64/',
  enabled  => 1,
  gpgcheck => 0,
}

package {[
  'munge',
  'slurm',
  'slurm-devel',
  'slurm-munge',
  'slurm-pam_slurm',
  'slurm-perlapi',
  'slurm-plugins',
  'slurm-sjobexit',
  'slurm-sjstat',
  'slurm-slurmdb-direct',
  'slurm-slurmdbd',
  'slurm-sql',
  'slurm-torque',
]:
  ensure  => latest,
  require => Yumrepo['slurm'],
}


# munge may try to startup before cloud-init has run and injected munge.key
# mangle its unit file so that it requires cloud-config.target
#
# augtool> set /files/lib/systemd/system/munge.service/Unit/After[value = 'cloud-config.target']/value cloud-config.target
# augtool> print /files/lib/systemd/system/munge.service/Unit/After[value = 'cloud-config.target']
augeas { 'munge-after-cloud-init':
  context => '/files/lib/systemd/system/munge.service/Unit',
  changes => "set After[value = 'cloud-config.target']/value cloud-config.target",
  onlyif  => "match After[value = 'cloud-config.target'] != 'cloud-config.target'",
  require => Package['munge'],
  before  => Service['munge'],
}

service { 'munge':
  enable  => true,
  require => Package['munge'],
}

service { 'slurm':
  enable  => true,
  require => Package['slurm'],
}

user { 'slurm':
  ensure     => present,
  gid        => 778,
  managehome => false,
  system     => true,
}

group { 'slurm':
  ensure => present,
  gid    => 778,
  system => true,
}

# XXX wrong way to do this -- should generate dynamically when terraform is run
# or stand up a local DNS resolver
host { 'slurm-ctrl':
  ensure => 'present',
  ip     => '192.168.52.10',
}
host { 'slurm-slave1':
  ensure => 'present',
  ip     => '192.168.52.11',
}
host { 'slurm-slave2':
  ensure => 'present',
  ip     => '192.168.52.12',
}
host { 'slurm-slave3':
  ensure => 'present',
  ip     => '192.168.52.13',
}
host { 'slurm-slave4':
  ensure => 'present',
  ip     => '192.168.52.14',
}
host { 'slurm-slave5':
  ensure => 'present',
  ip     => '192.168.52.15',
}
host { 'slurm-slave6':
  ensure => 'present',
  ip     => '192.168.52.16',
}
host { 'slurm-slave7':
  ensure => 'present',
  ip     => '192.168.52.17',
}
host { 'slurm-slave8':
  ensure => 'present',
  ip     => '192.168.52.18',
}
host { 'slurm-slave9':
  ensure => 'present',
  ip     => '192.168.52.19',
}
host { 'slurm-slave10':
  ensure => 'present',
  ip     => '192.168.52.20',
}

# XXX currently we are punting on this and using the same image for all nodes.
# Useless NFS exports shouldn't case too much trouble.
if $::slurm_node_type == 'ctrl' {
    file { '/scratch0':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '1777',
  }

  class { '::nfs::server':
    nfs_v4                     => true,
    nfs_v4_export_root_clients =>
      '192.168.52.0/24(rw,fsid=root,insecure,no_subtree_check,async,no_root_squash)'
  }
  nfs::server::export{ '/scratch0':
    ensure  => 'mounted',
    clients => '192.168.52.0/24(rw,insecure,no_subtree_check,async,no_root_squash) localhost(rw)',
    require => File['/scratch0'],
  }
}

nfs::client::mount { 'scratch0':
  ensure   => 'present', # do not attempt to mount from packer
  server   => 'slurm-ctrl',
  share    => '/scratch0',
  mount    => '/mnt/scratch0',
  remounts => true,
  atboot   => true,
}
