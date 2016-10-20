
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
            f.write(data.to_json)
          end
        end
      end
      class HistoryFileSink < Sink
        require 'json'

        attr_reader :file

        def initialize
          @file    = Monitor::Config[:history_file]
          @history = if File.exist?(file)
                       JSON.parse(File.read(file)) rescue []
                     else
                       []
                     end
        end

        # will append data to the history file
        # within 5 seconds of last deployment
        # the array is a FIFO
        def receive(data)
          history = [data] + history.take(Monitor::Config[:history_file_size] - 1)

          File.write(file, history.to_json)
        end
      end
    end
  end
end
