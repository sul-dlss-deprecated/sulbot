# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'sulbot'
set :repo_url, 'https://github.com/sul-dlss/sulbot.git'
set :user, 'sulbot'
set :home_directory, "/opt/app/#{fetch(:user)}"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "#{fetch(:home_directory)}/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'pids', 'node_modules')

# Default value for default_env is {}
set :default_env, fetch(:default_env, {}).merge('PATH' => "#{fetch(:deploy_to)}/current/node_modules/.bin:#{fetch(:deploy_to)}/current/node_modules/hubot/node_modules/.bin:$PATH")

# Default value for keep_releases is 5
set :keep_releases, 3

namespace :deploy do
  desc "Sets up the log file, then sources EnvVars & starts Hubot"
  task :start do
    log_file = "#{shared_path}/log/hubot.log"
    # If we've got a log file already, mark that a deployment occurred
    on roles(:app) do
      execute "if [ -e #{log_file} ]; then echo \"\n\nDeployment #{release_timestamp}\n\" >> #{log_file}; fi"
      # Start Hubot!
      execute "source #{fetch(:home_directory)}/.bashrc && \
        cd #{release_path} && \
        forever start -p #{shared_path} --pidFile #{shared_path}/pids/hubot.pid -a -l #{shared_path}/log/hubot.log -c coffee node_modules/.bin/hubot -a slack -d"
    end
  end

  desc "Stop Hubot"
  task :stop do
    on roles(:app) do
      test "source #{fetch(:home_directory)}/.bashrc && \
        cd #{fetch(:deploy_to)}/current && \
        forever stop $(cat #{shared_path}/pids/hubot.pid)"
    end
  end

  desc "Install necessary Node modules, then move them to the correct path"
  task :npm_install do
    on roles(:app) do
      execute "cd #{release_path} && npm install"
    end
  end

  desc "Base task to restart Hubot after a deployment if he's already running"
  task :restart do
    invoke "deploy:stop"
    invoke "deploy:start"
  end
end
after "deploy:published", "deploy:restart"
before "deploy:updated", "deploy:npm_install"
