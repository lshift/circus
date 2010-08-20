require 'sinatra'

get '/acts/:name' do |name|
  fn = File.join(CONFIG.data_dir, name)
  
  halt 404, "Act #{name} not found" unless File.exists? fn
  
  content_type 'application/binary'
  File.read(fn)
end

put '/acts/:name' do |name|
  fn = File.join(CONFIG.data_dir, name)
  
  File.open(fn, 'wb') do |f|
    f.write(request.body.read)
  end
  
  "ok"
end