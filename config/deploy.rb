set :application, 'sulbot'
set :repo_url, 'https://github.com/sul-dlss/sulbot.git'
set :user, 'sulbot'
set :home_directory, "/opt/app/#{fetch(:user)}"

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "#{fetch(:home_directory)}/#{fetch(:application)}"

# Default value for linked_dirs is []
set :linked_dirs, %w{log pids node_modules}

# Default value for default_env is {}
set :default_env, { 'PATH' => "#{fetch(:deploy_to)}/current/node_modules/.bin:#{fetch(:deploy_to)}/current/node_modules/hubot/node_modules/.bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

namespace :deploy do
  desc "Start server"
  after :finished, :restart do
    on roles(:app) do
      within release_path do
        execute "source #{fetch(:home_directory)}/.bashrc && cd #{release_path} && npm run pm2"
      end
    end
  end
end
