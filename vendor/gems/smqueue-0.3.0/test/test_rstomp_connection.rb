require File.dirname(__FILE__) + '/helper'

class TestRStompConnection < Test::Unit::TestCase

  # Tests to see if when a primary queue falls over whether it rollsover to use the secondary.
  test "if primary queue fails should rollover to secondary" do
    TCPSocket.expects(:open).with("localhost", 61613).raises RStomp::RStompException
    TCPSocket.expects(:open).with("secondary", 1234).returns true
    
    stub_connection_calls_to_queue
    SMQueue.new(:configuration => YAML.load(configuration)).connect
  end

  # Tests to see if when a primary queue falls over whether it rollsover to use the secondary even for unreliable queues.
  test "if primary queue fails should rollover to secondary even if the queue is unreliable" do
    TCPSocket.expects(:open).with("localhost", 61613).raises RStomp::RStompException
    TCPSocket.expects(:open).with("secondary", 1234).returns true

    stub_connection_calls_to_queue
    SMQueue.new(:configuration => YAML.load(configuration)).connect
  end

  test "multiple calls to connect should swap hosts and ports appropriately" do
    TCPSocket.expects(:open).with("localhost", 61613).raises(RStomp::RStompException).once
    TCPSocket.expects(:open).with("secondary", 1234).returns(true).at_least(2)

    stub_connection_calls_to_queue
    queue = SMQueue.new(:configuration => YAML.load(configuration))
    2.times { queue.connect }
  end
  
private

  def configuration
      yaml = %[
    :adapter: :StompAdapter
    :host: localhost
    :port: 61613
    :secondary_host: secondary
    :secondary_port: 1234
    :name: /topic/smput.test
    :reliable: true
    :reconnect_delay: 5
    :subscription_name: test_stomp
    :client_id: hello_from_stomp_adapter
    :durable: false
    ]
  end
  
  def stub_connection_calls_to_queue
    RStomp::Connection.any_instance.stubs(:_transmit).returns true
    RStomp::Connection.any_instance.stubs(:_receive).returns true
    RStomp::Connection.any_instance.stubs(:sleep)    
  end
  
end