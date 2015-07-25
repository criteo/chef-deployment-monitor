
class Monitor
  class Sink
    def receive(data)
      raise "must be implemented by subclass"
    end
  end

  class RmqSink
    def initialize
      @conn = Bunny.new(:hostname => MQSERVER)
      @conn.start

      @ch = @conn.create_channel
      @q  = @ch.queue(MQQUEUE, :durable => true)
    end

    def receive(data)
      @q.publish(data, :persistent => true, :content_type => "application/json")
    end
  end
end
