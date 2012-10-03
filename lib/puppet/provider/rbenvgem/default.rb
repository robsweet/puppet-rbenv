Puppet::Type.type(:rbenvgem).provide :default do
  desc "Maintains gems inside an RBenv setup"

  commands :su => 'su'

  def install
    args = ['install', '--no-rdoc', '--no-ri']
    args << "-v#{resource[:ensure]}" if !resource[:ensure].kind_of?(Symbol)
    args << gem_name

    output = gem(*args)
    fail "Could not install: #{output.chomp}" if output.include?('ERROR')
  end

  def uninstall
    gem 'uninstall', '-aIx', gem_name
  end

  def latest
    @latest ||= list(:remote)
  end

  def current
    return nil if list.empty?
    return [resource[:ensure]] if list.include?(resource[:ensure])
    [ list.join(',') ]
  end

  private
    def gem_name
      resource[:gemname]
    end

    def gem(*args)
      exec_path = "#{resource[:rbenv]}/bin:#{resource[:rbenv]}/shims:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
      exe = "RBENV_VERSION=#{resource[:ruby]} PATH=#{exec_path} gem"
      su('-', resource[:user], '-c', [exe, *args].join(' '))
    end

    def list(where = :local)
      args = ['list', where == :remote ? '--remote' : '--local', "#{gem_name}$"]

      gem(*args).lines.map do |line|
        line =~ /^(?:\S+)\s+\((.+)\)/

        return nil unless $1

        # Fetch the version number
        ver = $1.split(/,\s*/)
        ver.empty? ? nil : ver
      end.first
    end
end
