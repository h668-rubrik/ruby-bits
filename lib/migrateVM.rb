require 'celluloid/current'


class MigrateVM
  include Celluloid

# Get vmWare Hosts for the Cluster, merging vcenter name into the hash
  def migrate_vm(vmobj)

    #    vmlist.each do |vmobj|
    logme("#{vmobj['VMName']}","Begin Workflow","#{self.current_actor}")

# Get vCenters incase we need to refresh them on Rubrik
    vcenter_info = getFromApi('/api/v1/vmware/vcenter')['data']
    vcenter_ids = {}
    vcenter_info.each do |v|
      vcenter_ids[v['name']] = v['id']
    end

    refresh_vcenter = JSON.parse(setToApi('/api/v1/vmware/vcenter/' + vcenter_ids[vmobj['fromVCenter']] + '/refresh','',"post"))['id']
    refresh_status = getFromApi('/api/v1/vmware/vcenter/request/' + refresh_vcenter)['status']
    last_refresh_status = refresh_status
    while refresh_status != "SUCCEEDED"
      refresh_status = getFromApi('/api/v1/vmware/vcenter/request/' + refresh_vcenter)['status']
      if refresh_status != last_refresh_status
        logme("#{vmobj['VMName']}","Updating VCenter Data",refresh_status.capitalize)
        sleep 10
      end
      last_refresh_status = refresh_status
      logme("#{vmobj['VMName']}","Ping",refresh_status)
    end

# Shutdown the VM and monitor to completion
    logme("#{vmobj['VMName']}","Checking Power State","Started")
    shutdownVm(Creds["fromVCenter"],vmobj)

# Disconnect CD's
    logme("#{vmobj['VMName']}","Checking VirtualCdrom","Started")
    checkCD(Creds["fromVCenter"],vmobj)

# Need to remove custom config (spec.managedBy.extensionKey)
    logme("#{vmobj['VMName']}","Check spec.managedBy","Started")
    checkManagedBy(Creds["fromVCenter"],vmobj)

# Snapshot the VM and monitor to completion
    id=findVmItem(vmobj['VMName'],'id')
    effectiveSla = Sla_hash[findVmItem(vmobj['VMName'], 'effectiveSlaDomainId')]
    logme("#{vmobj['VMName']}","Request Snapshot",id)
    snapshot_job = JSON.parse(setToApi('/api/v1/vmware/vm/' + id + '/snapshot','',"post"))['id']
    logme("#{vmobj['VMName']}","Monitor Snapshot Request",snapshot_job)
    snapshot_status = ''
    last_snapshot_status = ''
    while snapshot_status != "SUCCEEDED"
      snapshot_status = getFromApi('/api/v1/vmware/vm/request/' + snapshot_job)['status']
      if snapshot_status != last_snapshot_status
        logme("#{vmobj['VMName']}","Monitor Snapshot",snapshot_status.capitalize)
        sleep 30
      end
      last_snapshot_status = snapshot_status
      logme("#{vmobj['VMName']}","Ping",snapshot_status)
    end

# Retrieve the latest snaphot it Instant Recover
    h=getFromApi("/api/v1/vmware/vm/#{id}/snapshot")
    latestSnapshot =  h['data'][0]['id']
    logme("#{vmobj['VMName']}","Get Snapshot ID",latestSnapshot)

# Assign a host to Instant recover the VM to
    hl = []
    VmwareHosts["data"].each do |vh|
      vcid = vh['computeClusterId'].scan(/^.*\:+(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})-.*$/)
      if VmwareVCenters[vcid] == vmobj['toVCenter']
        hl.push(vh["id"])
      end
    end
    myh=hl.sample(1)[0]
    logme("#{vmobj['VMName']}","Assign New Host","#{myh}")

# Instant Recover the VM
    logme("#{vmobj['VMName']}","Request Instant Recovery",id)
    recovery_job = JSON.parse(setToApi('/api/v1/vmware/vm/snapshot/' + latestSnapshot + '/instant_recover',{ "vmName" => "#{vmobj['VMName']}","hostId" => "#{myh}"},"post"))['id']
    logme("#{vmobj['VMName']}","Instant Recovery Request",recovery_job)
    recovery_status = ''
    last_recovery_status = ''
    while recovery_status != "SUCCEEDED"
      recovery_status = getFromApi('/api/v1/vmware/vm/request/' + recovery_job)['status']
      if recovery_status != last_recovery_status
        logme("#{vmobj['VMName']}","Monitor Recovery",recovery_status.capitalize)
        sleep 10
      end
      last_recovery_status = recovery_status
      logme("#{vmobj['VMName']}","Ping",recovery_status)
    end

# Swap the PortGroup (Don't know how this happens yet)
    logme("#{vmobj['VMName']}","Change Port Group","AIG TASK")
  #  changePortGroup(vmobj['toVCenter'],Options.vcenteruser,Options.vcenterpw,vmobj['toDatacenter'],vmobj['VMName'])


# Start the VM
    startVm(Creds["toVCenter"],vmobj)

# VMotion to production storage
    logme("#{vmobj['VMName']}","VMotion from Rubrik","Started")
    vMotion(Creds["toVCenter"],vmobj)

# Remove Instant Recover from Rubrik
    recovery_result = getFromApi('/api/v1/vmware/vm/request/' + recovery_job)['links']
    recovery_result.each do |r|
      if r['rel'] == "result"
        pp r['href']
        mount_id = r['href'].scan(/^.*(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})$/)
      end
    end
    puts mount_id
    logme("#{vmobj['VMName']}","Remove Live Mount",mount_id)
    remove_job = JSON.parse(setToApi('/api/v1/vmware/vm/snapshot/mount/' + mount_id + "?force=true",'',"delete"))['id']
    logme("#{vmobj['VMName']}","Remove Mount Requested",remove_job)
    remove_status = ''
    last_remove_status = ''
    while remove_status != "SUCCEEDED"
      remove_status = getFromApi('/api/v1/vmware/vm/request/' + remove_job)['status']
      if remove_status != last_remove_status
        logme("#{vmobj['VMName']}","Monitor Remove",remove_status.capitalize)
        sleep 10
      end
      last_remove_status = remove_status
      logme("#{vmobj['VMName']}","Ping",remove_status)
    end
    logme("#{vmobj['VMName']}","Reset SLA Domain",effectiveSla)
    setSla(id,effectiveSla)
    logme("#{vmobj['VMName']}","Work Complete","#{self.current_actor}")
  end
end
