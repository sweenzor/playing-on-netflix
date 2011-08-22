require "bundler/capistrano"

# Rake helper task.
# http://pastie.org/255489
# http://geminstallthat.wordpress.com/2008/01/27/rake-tasks-through-capistrano/
# http://ananelson.com/said/on/2007/12/30/remote-rake-tasks-with-capistrano/
def run_remote_rake(rake_cmd)
  rake_args = ENV['RAKE_ARGS'].to_s.split(',')
  cmd = "cd #{fetch(:latest_release)} && #{fetch(:rake, "rake")} RAILS_ENV=#{fetch(:rails_env, "production")} #{rake_cmd}"
  cmd += "['#{rake_args.join("','")}']" unless rake_args.empty?
  run cmd
  set :rakefile, nil if exists?(:rakefile)
end


#############################################################
# Application
#############################################################
set :application, "netflix"
set :deploy_to, "~/apps/#{application}"
set :keep_releases, 4 

# #############################################################
# # Git & Github
# #############################################################

set :scm, :git
set :branch, "master"
set :repository, "git@github.com:mattswe/playing-on-netflix.git"
set :deploy_via, :remote_cache


# #############################################################
# # Servers
# #############################################################

set :user, "deploy"
set :domain, "50.18.105.32"
server domain, :app, :web
role :db, domain, :primary => true


# #############################################################
# # Settings
# #############################################################

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
set :use_sudo, false
set :scm_verbose, true


# #############################################################
# # Deploy
# #############################################################

namespace :deploy do
  task :start do
    run "/etc/init.d/unicorn start /etc/unicorn/#{application}.conf"
  end

  task :stop do
    run "/etc/init.d/unicorn stop /etc/unicorn/#{application}.conf"
  end

  task :restart do
    run "/etc/init.d/unicorn restart /etc/unicorn/#{application}.conf"
  end

  desc "Restart Resque Workers"
  task :restart_workers, :roles => :db do
    run_remote_rake "resque:restart_workers"
  end
end

namespace :web do
  desc "disable the site and display maintenance page, needs nginx redirect"
  task :disable, :roles => :web do
    require 'erb'
    template = File.read('app/views/layouts/maintenance.html.erb')
    page = ERB.new(template).result(binding)

    put page, "#{deploy_to}/shared/system/maintenance.html", :mode => 0777
  end

  desc "enable the site by removing maintenance page, needs nginx redirect"
  task :enable, :roles => :web do
    run "rm #{shared_path}/system/maintenance.html"
  end
  
  desc "precompile the assets"
  task :precompile_assets, :roles => :web, :except => { :no_release => true } do
    run "cd #{current_path}; rm -rf public/assets/*"
    run "cd #{current_path}; RAILS_ENV=production bundle exec rake assets:precompile"
  end
  
  desc "Copy resque-web assets into public folder"
  task :copy_resque_assets do
    target = File.join(release_path,'public','resque')
    run "cp -r `cd #{release_path} && bundle show resque`/lib/resque/server/public #{target}"
  end
end

before "deploy:restart", 'web:precompile_assets'
# after "web:precompile_assets", "web:copy_resque_assets"
# after "deploy:symlink", "deploy:restart_workers"

# maintenance page
# before "deploy:restart", 'web:disable'
# after "deploy:restart", 'web:enable'


