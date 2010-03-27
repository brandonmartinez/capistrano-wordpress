# This gem is based off the work of many others. Here are most of the references:

# http://openmonkey.com/articles/2010/01/making-your-capistrano-recipe-book
# http://railstips.org/2008/11/24/gitn-your-shared-host-on
# http://railstips.org/2008/12/14/deploying-rails-on-dreamhost-with-passenger
# http://code.whomwah.com/ruby/capistrano1/deploy.rb
# http://www.capify.org/index.php/Variables


require 'capistrano/wordpress/common'
 
# Check that Capistrano exists (need version 2 or higher)
unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ext/multistage requires Capistrano 2"
end
  
# Modify the configuration to our needs
Capistrano::Configuration.instance.load do
 
  # User details
  _cset(:user)                  { abort "Please specify your username for the server:   set :user, 'username'" }
  
  # Domain details
  _cset(:domain)                { abort "Please specify your domain name for deployment:   set :domain, 'yourdomain.com'" }

  # Application/Theme details
  _cset(:application)           { "#{:domain}" }
  _cset(:theme_name)            { about "Please specify a theme name (no spaces, please):   set :theme_name, 'themename'" }
  _cset(:current_dir)           { "#{:theme_name}" }

  # SCM settings
  _cset(:appdir)                { "/home/#{user}/deployments/#{application}" }
  _cset(:scm)                   { 'git' }
  _cset(:scm_verbose)           { true }
  _cset(:repository)            { "#{user}@#{domain}:git/#{application}.git"}
  _cset(:branch)                { 'master' }
  _cset(:deploy_via)            { 'remote_cache' }
  _cset(:git_shallow_clone)     { 1 }
  _cset(:deploy_to)             { "/home/#{user}/#{domain}/wp-content/themes/" }
  _cset(:releases_path)         { "/home/#{user}/cap/#{domain}/releases/" }
  _cset(:shared_path)           { "/home/#{user}/cap/#{domain}/shared/" }
  _cset(:use_sudo)              { false }
  _cset(:keep_releases)         { 100 }

  # Git settings for capistrano
  default_run_options[:pty]     = true # needed for git password prompts
  ssh_options[:forward_agent]   = true # use the keys for the person running the cap command to check out the app

  #
  # Dependencies
  #

  require 'capistrano/amc/config'
  require 'capistrano/amc/database'
  require 'capistrano/amc/assets'

  #
  # Recipes
  #
  
  namespace :deploy do

     desc "A macro-task that updates the code and fixes the symlink."
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

     desc "Remove the WordPress cache and killall php5 instances"
     task :after_deploy do
       cleanup
       run "rm -rf ~/#{domain}/wp-content/cache/"
       run "killall php5.cgi"
       run "killall php5.cgi"
       run "killall php5.cgi"
       run "killall php5.cgi"
       run "killall php5.cgi"
     end

   end
end