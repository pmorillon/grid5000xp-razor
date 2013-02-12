require 'xp5k'

XP5K::Config.load
xp = XP5K::XP.new(:logger => logger)
experiment_walltime = XP5K::Config[:walltime] || '2:00:00'
SSH_CMD = "ssh -o ConnectTimeout=10"

xp.define_job({
  :resources  => "nodes=1,walltime=#{experiment_walltime}",
  :site       => XP5K::Config[:site] || 'rennes',
  :types      => ["deploy"],
  :name       => "razor_server",
  :command    => "sleep 86400"
})

xp.define_deployment({
  :site           => XP5K::Config[:site],
  :environment    => 'wheezy-x64-nfs',
  :jobs           => %w{ razor_server },
  :key            => File.read(XP5K::Config[:public_key]),
  :notifications  => ["xmpp:#{XP5K::Config[:user]}@jabber.grid5000.fr"]
})

role :razor do
  xp.job_with_name('razor_server')['assigned_nodes'].first
end

namespace :xp do
  before "xp:run", :jobs
  before "xp:run", :deploy
  before "xp:run", :sync
  before "xp:run", "install:puppet"
  before "xp:run", "provision:server"

  desc "Running Razor experiment"
  task :run do
    logger.debug "Razor deployed ! try cap ssh:razor"
  end
end


desc 'Init jobs'
task :jobs do
  xp.submit
end

desc 'Deploy with kadeploy'
task :deploy do
  xp.deploy
end

desc 'Experiment status'
task :status do
  xp.status
end

desc "Clean all running jobs"
task :clean do
  logger.debug "Clean all running jobs..."
  xp.clean
end

namespace :ssh do
  desc 'SSH as root on the Razor server'
  task :razor do
    logger.debug "ssh root@#{getFirstNodeForJob(xp, 'razor_server')}"
    safe_exec('ssh', "root@#{getFirstNodeForJob(xp, 'razor_server')}")
  end
end

desc 'Sync experiments file into your home directory on Grid\'5000'
task :sync do
  set :user, XP5K::Config[:user]
  logger.debug "Sync experiment environment on the #{XP5K::Config[:site]} frontend..."
  %x{rsync -e '#{SSH_CMD}' -rl --delete --exclude '.git*' #{File.expand_path(File.join(Dir.pwd, '.'))} #{XP5K::Config[:user]}@frontend.#{XP5K::Config[:site]}.grid5000.fr:~/xps/}
end

namespace :install do
  desc 'Install puppet on server and nodes'
  task :puppet, :roles => :razor do
    set :user, 'root'
    logger.debug 'Install Puppet...'
    run "http_proxy=http://proxy:3128 PUPPET_VERSION=3.0.1 sh /home/#{XP5K::Config[:user]}/xps/grid5000xp-razor/puppet/librarian-modules/puppet/files/scripts/puppet_install.sh"
  end
end

namespace :provision do

  before 'provision:razor', :sync

  desc 'Provisioning Razor server'
  task :razor, :roles => :razor do
    set :user, "root"
    logger.debug "Provisioning Razor with Puppet"
    run "http_proxy=http://proxy:3128 puppet apply --modulepath /home/#{XP5K::Config[:user]}/xps/grid5000xp-razor/puppet/librarian-modules/:/home/#{XP5K::Config[:user]}/xps/grid5000xp-razor/puppet/xp-modules/ -e 'include razor5k'"
  end

end


# Remove built-in tasks :shell and :invoke
task :shell do
  # Nothing
end

task :invoke do
  # Nothing
end


def getFirstNodeForJob(xp, name)
  xp.job_with_name(name)['assigned_nodes'].first
end

# Definition from Vagrant sources (https://github.com/mitchellh/vagrant)
def safe_exec(command, *args)
  # Create a list of things to rescue from. Since this is OS
  # specific, we need to do some defined? checks here to make
  # sure they exist.
  rescue_from = []
  rescue_from << Errno::EOPNOTSUPP if defined?(Errno::EOPNOTSUPP)
  rescue_from << Errno::E045 if defined?(Errno::E045)
  rescue_from << SystemCallError

  fork_instead = false
  begin
    pid = nil
    pid = fork if fork_instead
    Kernel.exec(command, *args) if pid.nil?
    Process.wait(pid) if pid
  rescue *rescue_from
    # We retried already, raise the issue and be done
    raise if fork_instead

    # The error manifested itself, retry with a fork.
    fork_instead = true
    retry
  end
end
