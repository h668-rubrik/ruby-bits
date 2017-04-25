$LOAD_PATH.unshift File.expand_path('../lib/', __FILE__)
require 'parseoptions.rb'
require 'pp'

# Global options
@options = ParseOptions.parse(ARGV)

# Grab the SLAHash to make pretty names
if @options.file then
  if @options.assure then
    require 'getVm.rb'
    require 'uri'
    # do some file workflow
    ss = URI.encode(@options.assure.to_s)
    managedId=findVmItem(@options.vm,'managedId')
    h=getFromApi("/api/v1/search?managed_id=#{managedId}&query_string=#{ss}")
    h['data'].each do |s|
      puts s['path']
    end
  end
end

if @options.login then
   require 'getToken.rb'
   token=get_token()
end


if @options.dr then
    require 'getVm.rb'
    require 'uri'
    require 'json'
    require 'setToApi.rb'
    #Get Cluster ID
    clusterInfo=getFromApi("/api/v1/cluster/me")
    id=findVmItem(@options.vm,'id')
    #Get Latest Snapshot
    h=getFromApi("/api/v1/vmware/vm/#{id}/snapshot")
    latestSnapshot =  h['data'][0]['id']
    #Get vmWare Hosts for the Cluster
    vmwareHosts=getFromApi("/api/v1/vmware/host")
    hostList = Array.new
    vmwareHosts["data"].each do |vmwareHosts|
	hostList.push(vmwareHosts["id"]) if vmwareHosts["primaryClusterId"] === clusterInfo["id"]
    end
    o = setToApi('/api/v1/vmware/vm/snapshot/' + latestSnapshot + '/instant_recover',{ "vmName" => "#{@options.vm}","hostId" => "#{hostList[0]}","removeNetworkDevices" => true},"post")
end


if @options.sla then
  require 'getSlaHash.rb'
  require 'getFromApi.rb'
  require 'getVm.rb'
  sla_hash = getSlaHash()
  if @options.get then
    effectiveSla = sla_hash[findVmItem(@options.vm, 'effectiveSlaDomainId')]
    # Get the SLA Domain for node
    puts "#{effectiveSla}"
  end
  if @options.list then
    listData = getFromApi("/api/v1/vmware/vm?limit=9999")
    listData['data'].each do |s|
      lookupSla = s['effectiveSlaDomainId']
      if lookupSla == 'UNPROTECTED' then 
        #puts s['name'] + ", " + s['effectiveSlaDomainId'] + ", " + s['primaryClusterId'] 
      else
        slData = getFromApi("/api/v1/sla_domain/#{lookupSla}")
        if s['primaryClusterId'] == slData['primaryClusterId'] then
          result = "Good"
        else
          result = "BAD"
        end
        puts s['name'] + ", " + s['effectiveSlaDomainId'] + ", " + s['primaryClusterId'] + ", " + slData['primaryClusterId'] + ", " + result
      end
    end
    exit
  end
  effectiveSla = sla_hash[findVmItem(@options.vm, 'effectiveSlaDomainId')]
  if @options.assure && (effectiveSla != @options.assure) then
    require 'setSla.rb'
    if @options.assure == effectiveSla 
      puts "Looks like its set"
    else
      if sla_hash.invert[@options.assure]
        res = setSla(findVmItem(@options.vm, 'id'), sla_hash.invert[@options.assure])
        if !res.nil?
	  res = JSON.parse(res)
         # if res["effectiveSlaDomain"]["name"] == @options.assure 
         #   puts "#{@options.assure}"
         # end
        else
          puts "Rubrik SLA Domain does NOT exist, cannot comply"
        end
      end
    end
  end
end
