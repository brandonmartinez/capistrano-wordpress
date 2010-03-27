# This gem is based off the work of many others. Here are most of the references:

# http://openmonkey.com/articles/2010/01/making-your-capistrano-recipe-book
# http://railstips.org/2008/11/24/gitn-your-shared-host-on
# http://railstips.org/2008/12/14/deploying-rails-on-dreamhost-with-passenger
# http://code.whomwah.com/ruby/capistrano1/deploy.rb
# http://www.capify.org/index.php/Variables


require 'capistrano/mycorp/common'
 
# Get the default Capistrano configuration
configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)
  
# Modify the configuration to our needs
configuration.load do
  
#
# Configuration
#
 
# Multistage
# _cset(:default_stage) { 'dev' }
# 
# require 'capistrano/ext/multistage'
 
# User details
_cset :user,          'deployer'
_cset(:group)         { user }
 
# Application details
_cset(:app_name)      { abort "Please specify the short name of your application, set :app_name, 'foo'" }
set(:application)     { "#{app_name}.mycorp.com" }
_cset(:runner)        { user }
_cset :use_sudo,      false
 
# SCM settings
_cset(:appdir)        { "/home/#{user}/deployments/#{application}" }
_cset :scm,           'git'
set(:repository)      { "git@git.mycorp.net:#{app_name}.git"}
_cset :branch,        'master'
_cset :deploy_via,    'remote_cache'
set(:deploy_to)       { appdir }
 
# Git settings for capistrano
default_run_options[:pty]     = true # needed for git password prompts
ssh_options[:forward_agent]   = true # use the keys for the person running the cap command to check out the app
 
#
# Dependencies
#
 
require 'capistrano/amc/config'
require 'capistrano/amc/database'
require 'capistrano/amc/assets'
 
depend :remote, :directory, :writeable, "/home/#{user}/deployments"
 
#
# Runtime Configuration, Recipes & Callbacks
#
 
namespace :mycorp do
  task :ensure do
    # This is to determine whether the app is behind a load balancer on another host.
    # Default to false, which means that we do expect the :internal_balancer and :external_balancer
    # roles to exist.
    _cset(:standalone) { false }
        
    self.load do
      namespace :deploy do
        namespace :web do
          if standalone
            # These tasks will run on each app server
            desc "Disable requests to the app, show maintenance page"
            task :disable, :roles => :web do
              run "ln -nfs #{current_path}/public/maintenance.html #{current_path}/public/maintenance-mode.html"
            end
 
            desc "Re-enable the web server by deleting any maintenance file"
            task :enable, :roles => :web do
              run "rm -f #{current_path}/public/maintenance-mode.html"
            end
          else
            # These tasks will run on the load balancers
            desc "Disable requests to the app, show maintenance page"
            task :disable, :roles => :load_balancer do
              run "touch /etc/webdisable/#{app_name}"
            end
 
            desc "Re-enable the web server by deleting any maintenance file"
            task :enable, :roles => :load_balancer do
              run "rm -f /etc/webdisable/#{app_name}"
            end
          end
        end
      end
    end
  end
end
 
# Make mycorp:ensure run immediately after the stage-specific config is loaded
# This means it can make use of variables specified in _either_ the main deploy.rb
# or any of the stage files.
on :after, "mycorp:ensure", :only => stages
 
#
# Recipes
#
 
# Deploy tasks for Passenger
namespace :deploy do
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
end
 
 
 default_run_options[:pty] = true


 # The only options you'll probably have to modify
 set :user, 'appetites'
 set :domain, 'beta.appetitespersonalchef.com'
 set :application, 'appetitespersonalchef.com'
 set :current_dir, "appetites" # your theme name here

 # These options should stay the same; only change based on your host
 set :repository,  "#{user}@#{domain}:git/#{application}.git" 
 set :deploy_to, "/home/#{user}/#{domain}/wp-content/themes/"
 set :deploy_via, :remote_cache
 set :releases_path, "/home/#{user}/cap/#{domain}/releases/"
 set :shared_path, "/home/#{user}/cap/#{domain}/shared/"
 set :scm, 'git'
 set :branch, 'master'
 set :git_shallow_clone, 1
 set :scm_verbose, true
 set :use_sudo, false
 set :ssh_options, {:forward_agent => true, :auth_methods => "publickey", :keys => %w(/Users/brandon/.ssh/id_dsa)}
 set :keep_releases, 100

 #ssh_options[:auth_methods] = "publickey"
 #ssh_options[:keys] = 

 role :web, "#{domain}"
 role :app, "#{domain}"
 role :db,  "#{domain}"

 namespace :deploy do

   desc <<-DESC
   A macro-task that updates the code and fixes the symlink.
   DESC
   task :default do
     transaction do
       update_code
       symlink
     end
   end

   task :update_code, :except => { :no_release => true } do
     on_rollback { run "rm -rf #{release_path}; true" }
     strategy.deploy!
   end

   task :after_deploy do
     cleanup
     run "rm -rf ~/#{domain}/wp-content/cache/"
     run "killall php5.cgi"
     run "killall php5.cgi"
     run "killall php5.cgi"
     run "killall php5.cgi"
     run "killall php5.cgi"
   end

   # desc "Link shared files"
   # task :before_symlink do
   #   run "ln -nfs #{deploy_to}/shared/system/media #{current_release}/media"
   # end

 end
 
end