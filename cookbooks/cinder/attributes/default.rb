default[:cinder][:use_syslog] = true

default[:cinder][:backend] = 'local'
default[:cinder][:glance_api_version] = 1
default[:cinder][:workers] = nil

#
# local backing file
#
default[:cinder][:iscsi_helper] = 'tgtadm'
default[:cinder][:backing_file_size] = '5G'
default[:cinder][:backing_file] = '/var/lib/cinder/volumes/cinder-volumes'
default[:cinder][:loop_dev] = '/dev/loop2'

#
# ceph
#
default[:cinder][:rbd_pool] = 'volumes'
default[:cinder][:rbd_user] = 'volumes'
default[:cinder][:rbd_key] = nil
default[:cinder][:rbd_store_chunk_size] = 8

#
# Quota
#
default[:cinder][:quota][:volumes] = 10
default[:cinder][:quota][:snapshots] = 10
default[:cinder][:quota][:gigabytes] = 1000

#
# conditional settings
#
case node[:cinder][:backend]
when 'local'
    default[:cinder][:volume_driver] = 'nova.volume.driver.ISCSIDriver'

when 'ceph'
    default[:cinder][:volume_driver] = 'cinder.volume.drivers.rbd.RBDDriver'
    default[:cinder][:glance_api_version] = 2

    # @todo 여기는 자동화 해야지요..
    case node[:fqdn]
    when 'compute01.stack'
        default[:cinder][:rbd_secret_uuid] = 'f1e626dd-694f-73c3-2a93-e4b7eaccad9f'
    when 'compute02.stack'
        default[:cinder][:rbd_secret_uuid] = '7d6d06c5-1494-d1c8-b516-8b1a6792e54e'
    when 'compute03.stack'
        default[:cinder][:rbd_secret_uuid] = '371fae29-cb7e-1d1d-b303-71d412d61de3'
    end
end
