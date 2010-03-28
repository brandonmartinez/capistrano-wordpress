#
# Credits
#

# This gem is based off the work of many others. Here are most of the references:

# http://openmonkey.com/articles/2010/01/making-your-capistrano-recipe-book
# http://railstips.org/2008/11/24/gitn-your-shared-host-on
# http://railstips.org/2008/12/14/deploying-rails-on-dreamhost-with-passenger
# http://code.whomwah.com/ruby/capistrano1/deploy.rb
# http://www.capify.org/index.php/Variables


Capistrano::Configuration.instance(:must_exist).load do
  
  #
  # Dependencies
  #

  require 'capistrano/recipes/deploy/scm'
  require 'capistrano/recipes/deploy/strategy'
  

  #
  # Variable Assignment Method
  #

  def _cset(name, *args, &block)
    unless exists?(name)
      set(name, *args, &block) 
    end
  end

  #
  # Variables
  #

  # User details
  _cset(:user)                  { abort "Please specify your username for the server:   set :user, 'username'" }

  # Domain details
  _cset(:domain)                { abort "Please specify your domain name for deployment:   set :domain, 'yourdomain.com'" }

  # Application/Theme details
  _cset (:application)          { domain }
  _cset (:theme_name)           { abort "Please specify a theme name (no spaces, please):   set :theme_name, 'themename'" }
  _cset (:current_dir)          { theme_name}

  # SCM settings
  set :appdir,               	"/home/#{user}/deployments/#{application}"
  set :scm,                   'git'
  set :scm_verbose,           true
  set :repository,            "#{user}@#{domain}:git/#{application}.git"
  set :branch,                'master'
  set :deploy_via,            'remote_cache'
  set :git_shallow_clone,     1
  set :deploy_to,            	"/home/#{user}/#{domain}/wp-content/themes/"
  set :releases_path,        	"/home/#{user}/cap/#{domain}/releases/"
  set :shared_path,          	"/home/#{user}/cap/#{domain}/shared/"
  set :use_sudo,              false
  set :keep_releases,         100

  # Git settings for capistrano
  default_run_options[:pty]     = true # needed for git password prompts
  ssh_options[:forward_agent]   = true # use the keys for the person running the cap command to check out the app

  #
  # Recipes
  #

  namespace :deploy do

    # Remove normal "rails" tasks; not needed for WP
    [:setup, :update, :update_code, :finalize_update, :symlink, :restart].each do |default_task|
      task default_task do 
        # ... ahh, silence!
      end
    end

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