# config valid for current version and patch releases of Capistrano
lock "~> 3.20.0"

require "dotenv/load"

set :application, ENV.fetch("APP_NAME", "homehome_log")
set :repo_url, ENV.fetch("GIT_REPO_URL")
set :deploy_to, ENV.fetch("DEPLOY_PATH")

set :rbenv_type, :user
set :rbenv_ruby, "4.0.0"

append :linked_files, "config/database.yml", ".env"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "vendor", "storage"
