$LOAD_PATH.unshift File.expand_path('./', __FILE__)
require 'getToken.rb'


# Produce hash of VM Details based on search
def getFromApi(p)
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
  response = conn.get p
  if response.status != 200
     msg = JSON.parse(response.body)['message']
     raise "Rubrik - Error (#{msg})"
  else
    o = JSON.parse(response.body)
    return o
    # Logged in and returning token
  end
end
