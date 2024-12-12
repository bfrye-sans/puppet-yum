#
# @summary Installs/removes rpms from local file/URL via yum install command.
#
# @note This can be better than using just the rpm provider because it will pull all the dependencies.
#
# @param source file or URL where RPM is available
# @param ensure the desired state of the package
# @param timeout optional timeout for the installation
# @param require_verify optional argument, will reinstall if rpm verify fails
# @param service_name optional argument, if present, will process service enable and status
# @param service_status used if service name is present, sets service status to running/stopped
# @param service_enable used if service name is present, sets true/false/manual/mask/delayed
#
# @example Sample usage:
#   yum::install { 'epel-release':
#     ensure => 'present',
#     source => 'https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm',
#   }
#
# @example Install openssh-server package and service options:
#   yum::install { 'openssh-server':
#     ensure         => 'present',
#     source         => 'openssh-server',
#     service_name   => 'sshd',
#     service_status => 'running',
#     service_enable => true,
#   }
#
# @example Hiera install openssh-server package and service options:
#   yum::install:
#     'openssh-server':
#        ensure:         'present'
#        source:         'openssh-server'
#        service_name:   'sshd'
#        service_status: 'running'
#        service_enable: true
#
define yum::install (
  String                                             $source,
  Enum['present', 'installed', 'absent', 'purged']   $ensure  = 'present',
  Boolean                                            $require_verify = false,
  Optional[Integer]                                  $timeout = undef,
  Optional[String]                                   $service_name = undef,
  Enum['stopped', 'running', 'false', 'true']        $service_status = 'running',
  Enum['true', 'false', 'manual', 'mask', 'delayed'] $service_enable = 'true',
) {
  Exec {
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    environment => 'LC_ALL=C',
  }

  case $ensure {
    'present', 'installed', default: {
      if $require_verify {
        exec { "yum-reinstall-${name}":
          command => "yum -y reinstall '${source}'",
          onlyif  => "rpm -q '${name}'",
          unless  => "rpm -V '${name}'",
          timeout => $timeout,
          before  => Exec["yum-install-${name}"],
        }
      }

      exec { "yum-install-${name}":
        command => "yum -y install '${source}'",
        unless  => "rpm -q '${name}'",
        timeout => $timeout,
      }
    }

    if ($service_name != undef) {
      -> service { $service_name:
        ensure => $service_status,
        enable => $service_enable,
      }
    }

    'absent', 'purged': {
      package { $name:
        ensure => $ensure,
      }
    }
  }
}
