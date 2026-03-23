require 'rack'

class StaticServer
  def initialize(root = Dir.pwd)
    @handler = Rack::File.new(root)
  end

  def call(env)
    @handler.call(env)
  end
end
