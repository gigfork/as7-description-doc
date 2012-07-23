require 'rubygems'
require 'bundler/setup'
Bundler.require

get '/resource-description' do
  user = params['user']
  password = params['password']

  return [500, "missing user and password parameters"] unless user and password

  url = 'http://127.0.0.1:9990/management/'
  operation = {:operation => "read-resource-description",
      :recursive => params["recursive"] || false,
      :operations => params["operations"] || false,
      :inherited => params["inherited"] || false
    }
  res = AS7.query url, user, password, operation.to_json
  if res.code == 200
    [res.code,   {'Content-type' => 'application/json'}, res.body.to_s]
  else
    [res.code, res.headers, res.body.to_s]
  end
end

class AS7
  include HTTParty
  def AS7.query(url, user, password, operation)
    digest_auth user, password
    post url , :body => operation, :headers => {"Content-type" => "application/json"}
  end
end