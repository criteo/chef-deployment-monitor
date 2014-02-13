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
require 'chef/knife/cookbook_download'
require 'chef_monitor/log'

class Monitor
  class Item
    def initialize(data)
      @path = nil
      @name = data['name']
      @time = data['time'].freeze
      @user = data['user'].freeze
      @object = data['object'].freeze
      @server = data['server'].freeze
      @action = data['action'].freeze
      @version = data['version'] unless data['version'].nil?
      @organization = data['org'].freeze
    end
  
    attr_accessor :path
    attr_reader :name
    attr_reader :time
    attr_reader :user
    attr_reader :object
    attr_reader :action
    attr_reader :version
    attr_reader :organization
  
    def download(path)

      if @object == "cookbooks" 
        r = download_cookbook(path)
      else
        r = download_object(path)
      end

      (@version.nil? || @version.empty?) ? object = [@organization, @object, @name].join('/') : object = [@organization, @object, @name, @version].join('/') 

      if r == true
        Monitor::Log.new("Downloaded: " + object, 'INFO')
        return true 
      end
      if r.respond_to?("message")
        Monitor::Log.new(r.message + ' with object: ' + object , 'ERROR')
      else
        Monitor::Log.new('Error while downloading object: ' + object , 'ERROR')
      end
      return false
    end 
  
    def delete(path)
      file = nil
      items = [ path ]
      items << @organization
      items << @object
      if @name
        filename=@name + ".json" 
 
        if @object == "cookbooks"
          (@version.nil? || @version.empty?) ? filename=@name : filename=@name + "-" + @version
        end

        if @object == "data"
          (@version.nil? || @version.empty?) ? filename=@name : filename=@name + "/" + @version + ".json"
        end

        items << filename
      end
      file = items.join("/")
      delete_file(file)
    end

    def delete_file(file)
      FileUtils.rm_rf(file)
      Monitor::Log.new("Deleted   : " + file, 'INFO')
      true
    end
 
    def get_item_json(object)
      begin
        item = rest.get_rest(object)
        # item.delete('automatic') if item['automatric']
        item = view_node_data(item) if item.class == Chef::Node
        result = JSON.pretty_generate(item)
      rescue Exception => e
        Monitor::Log.new(e.message + ' with object: ' + @organization + "/" + object , 'ERROR')
        return nil
      end
      return result
    end

    def view_node_data(node)
      result = {}
      result["name"] = node.name
      result["chef_environment"] = node.chef_environment
      result["normal"] = node.normal_attrs
      result["run_list"] = node.run_list
      #result["default"]   = node.default_attrs
      #result["override"]  = node.override_attrs
      # result["automatic"] = node.automatic_attrs
      result
    end


    def commit(path)
      current_dir = Dir.pwd
      commit_dir = File.join(path, @organization)
      Dir.chdir(commit_dir)
      @version ? object = [@organization, @object, @name, @version].join('/') : object = [@organization, @object, @name].join('/')
      text = "User     : " + @user + "\nObject   : " + object + "\nAction   : " + @action + "\nLog Time : " + @time
      domain = %x(git config hooks.emaildomain) || "acme.com"
      domain = "@" + domain unless domain[0,1] == "@"        
      username = @user
      useremail = @user + domain
      %x(git config hooks.username #{username} )
      %x(git config hooks.useremail #{useremail} )
      %x(git add .)
      %x(git commit -am \"#{text}\")
      Dir.chdir(current_dir)
    end

    def commit_nohook(path)
      current_dir = Dir.pwd
      commit_dir = File.join(path, @organization)
      Dir.chdir(commit_dir)
      %x(git config hooks.exclude true)
      %x(git add .)
      %x(git commit -am \"no hook executed on this commit\")
      Dir.chdir(current_dir)
    end

    private

    def rest
      @rest ||= begin
        require 'chef/rest'
        Chef::REST.new(Chef::Config[:chef_server_url])
      end
    end

    def download_cookbook(path)
      begin
        args = ['cookbook', 'download', @name ]
        args.push @version if @version
        download = Chef::Knife::CookbookDownload.new(args)
        download_dir = File.join(path, @organization, @object)
        FileUtils.mkdir_p(download_dir) unless File.directory?(download_dir)
        download.config[:download_directory] = download_dir
        download.config[:latest] = true unless @version
        download.config[:force] = true
        result = (download.run())
        file = File.join(download_dir, @name + "-" + @version, ".gitignore")
        File.delete(file) if File.exist?(file)
        self.path = download_dir
      rescue Exception => e
        return e
      end
      return true
    end
  
    def download_object(path)
      args = [ @object, @name ]
      args.push(@version) if @version
      item = args.join('/')
      file = File.join(path, @organization, item + '.json' )
      data = get_item_json(item)
      unless data.nil?
        FileUtils.mkdir_p(File.dirname(file)) unless File.directory?(File.dirname(file))
        File.open(file, 'w') {|f| f.write(data)}
      end
      return true
    end

  end
end
