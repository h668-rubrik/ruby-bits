require 'net/https'
require 'pp'
require 'uri'

def setToApi(endpoint,l,type)
  endpoint = URI.encode(endpoint)
  @token.methods
  unless @token.nil?
    t = @token
    sv = @rubrikhost
  else
    (t,sv) = get_token
  end
  conn = Faraday.new(:url => 'https://' + sv)
  conn.ssl.verify = false
  conn.authorization :Bearer, t
#  conn.response :logger
  response = conn.public_send(type) do |req|
    req.url endpoint
    req.headers['Content-Type'] = 'application/json'
    req.body  = l.to_json
  end
  if response.status !~ /202|200/
    #Raise error for failed login
#    if msg = JSON.parse(response.body).message do
#      raise "Rubrik - Error (#{msg})"
#    end
    return response.body
  end
end
