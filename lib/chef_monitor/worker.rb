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
  class Worker
    def run
      conn = Bunny.new(:hostname => MQSERVER)
      conn.start
    
      ch = conn.create_channel
      q  = ch.queue(MQQUEUE, :durable => true)
      ch.prefetch(1)
    
      begin
        q.subscribe(:ack => true, :block => true) do |delivery_info, properties, body|
          if properties[:content_type] =~ /.*json/
            data = JSON.parse(body).to_hash
            Monitor::Log.new("Receiving : #{data}", "DEBUG") 
            data['object'] = nil unless ALLOWED_OBJECTS.include?(data['object'])

            unless data['object'].nil? || !File.directory?((File.join(DOWNLOAD_PATH, data['org'])))
              Chef::Config[:chef_server_url] = CHEF_URL + "/organizations/#{data['org']}"

              obj = Monitor::Item.new(data)
              if data['action'] == "DELETE"
                obj.delete(DOWNLOAD_PATH)
              else
                items = Monitor::ItemList.new(data)              
                items.each do |item|
                  if data['action'] == "PUT"
                    item.download(DOWNLOAD_PATH)
                  end
               
                  if data['action'] == "POST"
                    item.delete(DOWNLOAD_PATH)
                    item.download(DOWNLOAD_PATH)
                  end
                end
              end
              obj.commit(DOWNLOAD_PATH)
            else
              Monitor::Log.new("Ignoring  : #{data}", "DEBUG")
            end
          else
            Monitor::Log.new("Unknown   : #{body}", "ERROR")
          end
        ch.ack(delivery_info.delivery_tag)
        end
      rescue Interrupt => _
        conn.close
      end
    end

  end
end
