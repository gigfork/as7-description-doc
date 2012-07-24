require 'rubygems'
require 'bundler/setup'
Bundler.require

module TextFilter
  def double(input)
    input + input
  end
end

def generate_toc(resource)
  out = "<div id=toc>"
  out += "<li><a href='#root'>root</a></li>"
  if resource['children']
    out += "<ul>"
    resource['children'].each { |k, v| out += "<li><a href='##{k}'>#{k}</a></li>"}
    out += "</ul>"
  end
  out += "</div>"
  out.to_s
end

Liquid::Template.register_filter(TextFilter)

get '/resource-description' do
  user = params['user']
  password = params['password']

  return [500, "missing user and password parameters"] unless user and password

  url = 'http://127.0.0.1:9990/management/'
  operation = {:operation => "read-resource-description",
      :recursive => params["recursive"] || false,
      :operations => params["operations"] || false,
      :inherited => params["inherited"] || false,
      "json.pretty" => 1
    }
  res = AS7.query url, user, password, operation.to_json
  if res.code != 200
    [500, res.body.to_s]
  end

  result = JSON.parse(res.body.to_s)
  if result['outcome'] != "success"
    [500, res.body.to_s]
   end
   resource = result['result']
   out = Liquid::Template.parse(File.read('./views/header.liquid')).render
   out += generate_toc(resource)
   out += Liquid::Template.parse(File.read('./views/index.liquid')).render 'resource' => resource
   out += "<h2>Attributes</h2>"
   resource['attributes'].each { |k, v | out += Liquid::Template.parse(File.read('./views/attribute.liquid')).render('name' => k, 'attribute' => v, 'base' => 'root')}
   out += "<h2>Operations</h2>"
   resource['operations'].each { |k, v | out += Liquid::Template.parse(File.read('./views/operation.liquid')).render('name' => k, 'operation' => v, 'base' => 'root')}
   out += Liquid::Template.parse(File.read('./views/footer.liquid')).render
   out
end

get '/resource-description2' do
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