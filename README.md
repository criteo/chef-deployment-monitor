#CHEF-MONITOR

Chef monitor has one executable:
  - chef-logmon         (this will be activated on all frontend servers)

#CHEF-LOGMON:

The logmon tool will run on every frontend server within your HA environment or on the  
chefserver in a more basic environment and is responsible for the following tasks:  
  
  - Tail your NGINX log and record all POST/PUTS/DELETES  
  
#CONFIGURATION:

In order to execute both tools, you will need the following configuration settings:

    log_dir        "/var/log/chef-monitor"
    pid_dir        "/var/run/chef-monitor"
    mon_file       "/var/log/opscode/nginx/access.log"

#EXECUTION:
  
After these settings, you should be able to run the tools:  
On all your frontend servers:  

    chef-logmon run -- -C /opt/chef-monitor/config.rb     #<run interactive>
    chef-logmon start -- -C /opt/chef-monitor/config.rb   #<run as service>
    chef-logmon stop                                      #<stop service>

# Credits

This repo is based on the initial work of @schubergphilis in schubergphilis/chef-monitor-gem
