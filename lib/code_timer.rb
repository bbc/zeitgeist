module CodeTimer
  extend self
  ## timer(text, *args, &block)
  def timer(text, *args, &block)
    t = Time.now
    result = block.call
    logger.info("#{text} #{(Time.now - t).to_f} #{args.inspect}")
    result
  end
end
