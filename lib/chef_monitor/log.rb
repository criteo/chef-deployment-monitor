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
  class Log
    
    def initialize(text, type='INFO')
      case type.downcase
      when "INFO".downcase
        puts "[" + Time.now.iso8601 + "] INFO: " + text
      when "WARN".downcase
        puts "[" + Time.now.iso8601 + "] WARN: " + text
      when "ERROR".downcase
        puts "[" + Time.now.iso8601 + "] ERROR: " + text
      when "DEBUG".downcase
        puts "[" + Time.now.iso8601 + "] DEBUG: " + text if DEBUG
      else
        puts "[" + Time.now.iso8601 + "] UNKNOWN: " + text
      end
    end

  end
end
