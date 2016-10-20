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

require 'date'
require 'digest'

class Chef
  class Deployment
    class Monitor
      class Logmon
        def run
          sinks = [MarkerFileSink.new, HistoryFile.new]

          begin
            File.open(Monitor::Config[:mon_file]) do |mon|
              mon.extend(File::Tail)
              mon.interval = 5
              mon.backward(1)
              mon.tail do |line|
                data = scan(line)
                # skipping the objects 'checksum-.*' and 'reports'
                unless data.nil? || data['org'].nil? || data['object'] =~ /(^checksum-.*$|^reports$)/
                  data = format(data)
                  unless filter(data)
                    Monitor::Log.new(data.to_json, 'INFO')
                    data = digest(data)
                    sinks.each { |sink| sink.receive(data) }
                  end
                end
              end
            end
          end
        end

        def format(data)
          # convert to timestamp
          data_dup = data.dup
          data_dup['time'] = DateTime.strptime(data['time'], '%d/%b/%C:%T %z').to_time.to_i
          data_dup['server'] = data['server'].strip
          data_dup
        end

        def digest(data)
          md5 = Digest::MD5.new
          md5.update data.to_s
          data = data.dup
          data['digest'] = md5.hexdigest
          data
        end

        def filter(data)
          Monitor::Config[:blacklisted?].call(data)
        end

        def scan(line)
          @regex = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) - (.{0})- \[([^\]]+?)\]  "(\w+) ([^\s]+?) (HTTP\/1\.1)" (\d+) "(.*)" (\d+) "-" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)" "(.*)"/
          if line =~ @regex
            data = {}
            data['time']    = Regexp.last_match(3)
            data['user']    = Regexp.last_match(16)
            data['server']  = LOGMONNAME
            data['org']     = Regexp.last_match(5).split('/')[2] unless Regexp.last_match(5).split('/')[2].nil?
            data['object']  = Regexp.last_match(5).split('/')[3] unless Regexp.last_match(5).split('/')[3].nil?
            data['name']    = Regexp.last_match(5).split('/')[4] unless Regexp.last_match(5).split('/')[4].nil?
            data['version'] = Regexp.last_match(5).split('/')[5] unless Regexp.last_match(5).split('/')[5].nil?
            data['action']  = Regexp.last_match(4)
            return data
          end
          nil
        end
      end
    end
  end
end
