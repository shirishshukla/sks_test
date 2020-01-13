## Facters

## Linux /opt Free Space 
Facter.add(:free_space_opt) do
  confine :kernel => ['AIX','Linux']
  setcode do
    Facter::Core::Execution.exec('df -Pm /opt | tail -n 1 | awk \'{print $4}\'').chomp
  end 
end 

## Windows determine drives free space 
Facter.add(:win_disk_space) do
  confine :osfamily => :windows
  RES = Array.new
  setcode do
    DRIVE = ENV['HOMEDRIVE']
    CMD   = "#{DRIVE}\\Windows\\System32\\wbem\\WMIC.exe logicaldisk get deviceid,freespace"
    Facter::Util::Resolution.exec(CMD).split(/[\r\n]+/).each do |dsk|
      d = /^([A-Z]:)\s+(\d+)/.match(dsk)
      next unless d
      fs = d[1].gsub(%r{[\/\.:\-]}, '')
      freeMB  = (d[2].to_f / 1024 / 1024).floor
      RES << "#{fs}:#{freeMB}"
    end
	  RES
  end 
end 

## Linux Java Agent Version 
Facter.add(:appdynamics_java_agent_version) do
  confine :kernel => ['AIX','Linux']
  setcode do
    jarfile='/opt/appdynamics/app-agent/javaagent.jar'
    if File.file?("#{jarfile}")
      version_old_way = Facter::Core::Execution.exec("unzip -p #{jarfile} META-INF/MANIFEST.MF | grep Implementation-Version | awk {'print $4, $5'}")
      version_new_way = Facter::Core::Execution.exec("unzip -p #{jarfile} META-INF/MANIFEST.MF | grep appagent-version | awk {'print $NF'}")
      version = version_new_way =~ /(\d+\.)+\d+/ ? version_new_way[/(\d+\.)+\d+/] : version_old_way[/(\d+\.)+\d+/]
    end
  end
end

##  Linux Machine Agent Version 
Facter.add(:appdynamics_machine_agent_version) do
  confine :kernel => ['AIX','Linux']
  setcode do
    jarfile='/opt/appdynamics/machine-agent/machineagent.jar'
    if File.file?("#{jarfile}")
      version = Facter::Core::Execution.exec("unzip -p #{jarfile} META-INF/MANIFEST.MF | grep Implementation-Version | awk {'print $4'} | awk -Fv {'print $NF'}")
      version = version[/(\d+\.)+\d+/]
    end
  end
end

## Windows Facter to get installed apache ot tomcat status 
Facter.add(:apache_tomcat_installed_status) do
  confine :osfamily => :windows
  setcode do
    begin
      cmd = 'Get-Service'
      encoded_cmd = Base64.strict_encode64(cmd.encode('utf-16le'))
      VAL=`powershell.exe -encodedCommand #{encoded_cmd}` #.strip.split(/\n+|\r+/).reject(&:empty?)
      case
        when VAL.downcase.include?('apache')       # APACHE
          MODTYPE='Installed'
        when VAL.upcase.include?('tomcat')         # TOMCAT
          MODTYPE='Installed'
        else
          MODTYPE='NotInstalled'                   # Default
      end
    rescue
      MODTYPE='NotInstalled'                       # Default
    end
  end
end

## Windows Installed java agent version 
Facter.add(:win_appdynamics_java_agent_version) do
  confine :osfamily => :windows
  setcode do
    jarfile='/opt/appdynamics/app-agent/javaagent.jar'
    if File.file?("#{jarfile}")
      version_old_way = Facter::Core::Execution.exec("unzip -p #{jarfile} META-INF/MANIFEST.MF | grep Implementation-Version | awk {'print $4, $5'}")
      version_new_way = Facter::Core::Execution.exec("unzip -p #{jarfile} META-INF/MANIFEST.MF | grep appagent-version | awk {'print $NF'}")
      version = version_new_way =~ /(\d+\.)+\d+/ ? version_new_way[/(\d+\.)+\d+/] : version_old_way[/(\d+\.)+\d+/]
    end
  end
end

## Windows Installed .net agent version 

## Windows Installed machine agent version 

## END ##