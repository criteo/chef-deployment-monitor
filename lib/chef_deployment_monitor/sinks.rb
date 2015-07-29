
class Chef
  class Deployment
    class Monitor
      class Sink
        def receive(_data)
          fail 'must be implemented by subclass'
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
  end
end
