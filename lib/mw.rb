class MW
  def initialize(app)
    @app = app
  end
  def call(env)
    pp [:ENV, env]
    response = @app.call(env)
    pp [:RESPONSE, response]
    response
  end
end
