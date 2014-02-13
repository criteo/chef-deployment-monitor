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

require 'chef/client'
require 'chef_monitor/item'

class Monitor
  class ItemList < Array

    def initialize(data)
      @name = data['name']
      @time = data['time']
      @user = data['user']
      @object = data['object']
      @server = data['server']
      @action = data['action']
      @version = data['version'] unless data['version'].nil? || data['version'].empty?
      @organization = data['org']
      check_sub_items()
    end
  
    private

    def check_sub_items()
      if @object == "cookbooks" || @object == "data"
        if @name.nil? || @name.empty?
          add_sub_items(@object)
        elsif @version.nil? || @version.empty?
          add_sub_items(@object, @name)
        else
          add_item(@object, @name, @version)
        end
      elsif @name.nil? || @name.empty?
        add_sub_items(@object)
      else
        add_item(@object, @name)
      end
    end

    def add_sub_items(object, name=nil)
      items = get_sub_items(object, name)
      items.each do |item|
        res = item.split('/')
        add_item(res[0], res[1], res[2]) 
      end      
    end
  
    def get_sub_items(object, name=nil)
      col = []
      target = [ object, name ].join('/')
      items = get_rest_item(target)
      items.each do |item,value|
        if object == "data" || object == "cookbooks"
          if name.nil?
            col += get_sub_items(object, item)
          else
            col.push([object, name, item].join('/')) if object == "data"
            value['versions'].each {|ver| col << sub_item_parse(ver['url'])} if object == "cookbooks"
          end
        elsif object == "users"
          item.each { |k|  k.each {|sv| col << "users/" + sv['username'] unless sv['username'].nil? }} unless name
        else
          col << sub_item_parse(value) unless name
        end
      end
      return col
    end

    def sub_item_parse(str)
      str.gsub!(Chef::Config[:chef_server_url],"")
      str[1..-1] if str[0] == '/'
    end

    def get_rest_item(object)
      begin
        result = rest.get_rest(object)
      rescue Exception => e
        Monitor::Log.new(e.message + ' with object: ' + @organization + "/" + object , 'ERROR')
        return []
      end
      return result    
     end

    def add_item(object, name, version=nil)
      data = {}
      data['time'] = @time
      data['user'] = @user
      data['action'] = @action
      data['server'] = @server
      data['org'] = @organization
      data['object'] = object
      data['name'] = name
      data['version'] = version unless version.nil?
      self << Monitor::Item.new(data)
    end
  
    def rest
      @rest ||= begin
        require 'chef/rest'
        Chef::REST.new(Chef::Config[:chef_server_url])
      end
    end
  end
end
