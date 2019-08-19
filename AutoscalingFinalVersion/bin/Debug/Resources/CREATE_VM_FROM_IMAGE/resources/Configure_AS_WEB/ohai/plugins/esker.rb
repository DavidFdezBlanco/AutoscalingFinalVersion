Ohai.plugin(:Esker) do
  provides 'esker'
  depends 'filesystem'
  
  # Setup registry for access with proper type and access of READ
  def get_reg_type
    if ::RbConfig::CONFIG["target_cpu"] == "i386"
      reg_type = Win32::Registry::KEY_READ | 0x100
    elsif ::RbConfig::CONFIG["target_cpu"] == "x86_64"
      reg_type = Win32::Registry::KEY_READ | 0x200
    else
      reg_type = Win32::Registry::KEY_READ
    end
    return reg_type
  end

  # Get a single registry key value from a registry key path and specific key name
  def get_single_registry_key(key_path, key_name)
    result = ''
    Win32::Registry::HKEY_LOCAL_MACHINE.open(key_path, get_reg_type) do |reg|
      reg.each_value do |subkey, type, data|
        result = data if subkey == key_name
      end
    end
    return result
  end

  # Get all of the registry keys from a registry key path, output all registry keys at the path and the data from the matching key as a hash
  def get_registry_keys_from_dir(key_path)
    results = {}
    Win32::Registry::HKEY_LOCAL_MACHINE.open(key_path, get_reg_type) do |reg|
      reg.each_value do |subkey, type, data|
        results.merge!("#{subkey.downcase}" => "#{data}")
      end
    end
    return results
  end

  # Get the registry keys matching the provided key_name from a registry key_path. Outputs the key along with its value as a hash
  def get_multiple_single_registry_keys_from_dir(key_path, key_name)
    results = {}
    Win32::Registry::HKEY_LOCAL_MACHINE.open(key_path, get_reg_type) do |reg|
      reg.each_key do |key, _wtime|
        item = reg.open(key)
        value = item[key_name] rescue nil
        next if value.nil?
        results.merge!("#{key.downcase}" => "#{value}")        
      end
    end
    return results
  end

  # Does some regexing on the returned string from the registry in order to get the actual data we want (e.g. MAFAX87)
  def get_bccon_group
    text = get_single_registry_key('SOFTWARE\Wow6432Node\SSTAI\Connector Container\Connectors\SapBCCONOut', 'Filter')
    return text.match(/\(ident=([A-Z]+[0-9]*)\)/).captures.first rescue nil # Get first regex match
  end

  def get_product_drive_letter
    drive_letter = get_single_registry_key('SOFTWARE\Wow6432Node\SSTAI\Install', 'ProductRootDir')
    return drive_letter[0..1]
  end

  def get_product_temp_drive_letter
    drive_letter = get_single_registry_key('SOFTWARE\Wow6432Node\SSTAI\Directories', 'TempDir')
    return drive_letter[0..1]
  end

  # Old way to get it, new way does not depend on anything existing in registry
  # def get_azure_temp_drive_letter
  #   drive_letter = get_single_registry_key('SOFTWARE\Wow6432Node\SSTAI\Directories', 'HttpDepotDir')
  #   return drive_letter[0..1]
  # end

  def get_azure_temp_drive_letter
    temp_drive = null
    filesystem.to_a.each do |drive_letter, properties|
      properties.each do |key, value|
        if key.casecmp("volume_name") == 0 && value.casecmp("temporary storage") == 0
          temp_drive = drive_letter
        end
      end
    end
    return temp_drive
  end


  # Collects the data and places it into a mash which is then displayed by ohai when queried
  # This one collects only on Windows
  collect_data(:windows) do
    require "Win32/registry" unless defined?(Win32::Registry)
    esker Mash.new
    esker['product_root_dir'] = get_single_registry_key('SOFTWARE\Wow6432Node\SSTAI\Install', 'ProductRootDir')
    esker['product_drive_letter'] = get_product_drive_letter
    esker['product_temp_drive_letter'] = get_product_temp_drive_letter
	  esker['azure_temp_drive_letter'] = get_azure_temp_drive_letter
    esker['directories'] = get_registry_keys_from_dir('SOFTWARE\Wow6432Node\SSTAI\Directories')
    esker['connectors_enabled'] = get_multiple_single_registry_keys_from_dir('SOFTWARE\Wow6432Node\SSTAI\Connector Container\Connectors', 'State')
    esker['sap_pair'] = get_bccon_group
  end
end
