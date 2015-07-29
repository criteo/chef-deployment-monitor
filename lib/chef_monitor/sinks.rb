
class Monitor
  class Sink
    def receive(_data)
      fail 'must be implemented by subclass'
    end
  end

  class RmqSink < Sink
    def initialize
      @conn = Bunny.new(hostname: Monitor::Config[:mq_server])
      @conn.start

      @ch = @conn.create_channel
      @q  = @ch.queue(Monitor::Config[:mq_queue], durable: true)
    end

    def receive(data)
      @q.publish(data, persistent: true, content_type: 'application/json')
    end
  end

  class MarkerFileSink < Sink
    # will modify the marker file
    # last write data of marker file will be within 5 seconds
    # of last deployement
    def receive(data)
      File.open(Monitor::Config[:marker_file], 'w+') do |f|
        f.write(data['user'])
      end
    end
  end
end
