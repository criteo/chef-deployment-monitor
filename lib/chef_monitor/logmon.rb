#
# Author:: Sander Botman (<sander.botman@gmail.com>)
# Copyright:: Copyright (c) 2014 Sander Botman.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Monitor
  class Logmon

    def run
      conn = Bunny.new(:hostname => MQSERVER)
      conn.start

      ch = conn.create_channel
      q  = ch.queue(MQQUEUE, :durable => true)

      begin
        File.open(MON_FILE) do |mon|
          mon.extend(File::Tail)
          mon.interval = 5
          mon.backward(1)
          mon.tail { |line|
            data = scan(line)
            # skipping the objects 'checksum-.*' and 'reports'
            unless data.nil? || data['org'].nil? || data['object'] =~  /(^checksum-.*$|^reports$)/
              Monitor::Log.new(data, "INFO")
              q.publish(data, :persistent => true, :content_type => "application/json")
            end
          }
        end
      end
    end

    def scan(line)
      @regex = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - (.{0})- \[([^\]]+?)\]  "(PUT|DELETE|POST) ([^\s]+?) (HTTP\/1\.1)" (\d+) "(.*)" (\d+) "-" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)"/
      if line =~ @regex
        data = {}
        data['time']    = $3
        data['user']    = $16
        data['server']  = LOGMONNAME
        data['org']     = $5.split('/')[2] unless $5.split('/')[2].nil?
        data['object']  = $5.split('/')[3] unless $5.split('/')[3].nil?
        data['name']    = $5.split('/')[4] unless $5.split('/')[4].nil?
        data['version'] = $5.split('/')[5] unless $5.split('/')[5].nil?
        data['action']  = $4
        return data.to_json
      end
      return nil
    end

  end
end
