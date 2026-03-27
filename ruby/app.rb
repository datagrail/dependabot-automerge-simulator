require 'rack'

class StaticServer
  def initialize(root = Dir.pwd)
    @handler = Rack::Files.new(root)
  end

  def call(env)
    @handler.call(env)
  end
end
