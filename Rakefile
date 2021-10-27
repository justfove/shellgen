require 'tmpdir'

def step(description)
  description = "-- #{description} "
  description = description.ljust(80, '-')
  puts
  puts "\e[32m#{description}\e[0m"
end

def app_path(name)
  path = "/Applications/#{name}.app"
  ["~#{path}", path].each do |full_path|
    return full_path if File.directory?(full_path)
  end

  return nil
end

def app?(name)
  return !app_path(name).nil?
end

def link_file(original_filename, symlink_filename)
  original_path = File.expand_path(original_filename)
  symlink_path = File.expand_path(symlink_filename)
  if File.exists?(symlink_path)
    # Symlink already configured properly. Leave it alone.
    return if File.symlink?(symlink_path) and File.readlink(symlink_path) == original_path
    # Never move user's files without creating backups first
    number = 1
    loop do
      backup_path = "#{symlink_path}.bak"
      if number > 1
        backup_path = "#{backup_path}#{number}"
      end
      if File.exists?(backup_path)
        number += 1
        next
      end
      mv symlink_path, backup_path, :verbose => true
      break
    end
  end
  ln_s original_path, symlink_path, :verbose => true
end

namespace :install do

  desc 'Apt-get Update'
  task :update do
    step 'apt-get update'
    sh 'sudo apt-get update'
  end

  desc 'Install Vim'
  task :vim do
    step 'vim'
    sh 'sudo apt-get install vim'
  end

  desc 'Install tmux'
  task :tmux do
    step 'tmux'
    sh 'sudo apt-get install tmux'
  end

  desc 'Install ctags'
  task