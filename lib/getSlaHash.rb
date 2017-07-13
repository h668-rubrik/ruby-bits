require 'getFromApi.rb'
# Grab Requested [item] from hash and return ony that value
def getSlaHash()
  clusterId = Hash[getFromApi('/api/v1/cluster/me')]['id']
  hash = Hash[getFromApi("/api/v1/sla_domain?primary_cluster_id=local")]
  array = hash['data']
  # Go through the array and break out into hash
  out = Hash.new
  array.each do |x|
    out[x['id']] = x['name']
  end
  return out
end
