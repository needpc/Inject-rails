class MaterielNetScrap

  DOMAIN = "https://www.materiel.net"
  URL = "#{DOMAIN}/pc-portable/l409/page"

  def self.explore
    agent = Mechanize.new
    current = 1
    loop do
      begin
        page = agent.get(URL+current.to_s)
      rescue Mechanize::ResponseCodeError => e
        break if e.page.code == '404'
      end
      page.search('.c-product__meta a').each do |x|
        ad_url = DOMAIN + x[:href].split('#').first
        scrap_pc(ad_url) if ad_url.match(/produit/i)
      end
      current += 1
    end

  end


  # On appelle la méthode pour récupérer les infos sur un PC
  def self.scrap_pc(url)
    begin
      page = Mechanize.new.get(url)
    rescue Exception=>e
      return
    end

    pc = {}
    hash_main = {}
    hash_os = {}
    hash_cpu = {}
    hash_memory = {}
    hash_disk = {}
    hash_screen = {}
    hash_keyboard = {}
    hash_network = {}
    hash_graphics = {}

    page.search('table.c-specs__table tr').each do |x|
      hash_main[x.search('td.label').text.gsub(/\s+/,' ').strip] = x.search('td.value').text.gsub(/\s+/,' ').strip
    end

    pc[:url] = url
    pc[:price] = page.search('.o-product__price').text.gsub(/[[:space:]]/, '').to_f
    pc[:model] = page.at('.col-12.col-md-9 h1').text
    pc[:brand] = page.at(".d-none.d-md-block.col-md-3 a")[:href].match(/\/marque\/(.*?)\//)[1] rescue nil


    # Informations sur le système d'exploitation
    hash_os[:os_name] = extract_from_hash(hash_main, "Famille OS")
    hash_os[:os_family] = extract_from_hash(hash_main, "Système d'exploitation")
    hash_os[:os_included] = extract_from_hash(hash_main, "Système d'exploitation fourni") == "Oui" ? true : false


    # Informations sur le processeur
    hash_cpu[:cpu_name] = extract_from_hash(hash_main, "Type de processeur")
    hash_cpu[:cpu_model] = extract_from_hash(hash_main, "Processeur")
    hash_cpu[:cpu_brand] = extract_from_hash(hash_main, "Marque processeur")
    hash_cpu[:cpu_frequency] = extract_from_hash(hash_main, "Fréquence CPU")


    # Informations sur la mémoire
    hash_memory[:memory_size] = extract_from_hash(hash_main, "Taille de la mémoire")
    hash_memory[:memory_max_size] = extract_from_hash(hash_main, "Taille de mémoire Max")
    hash_memory[:memory_type] = extract_from_hash(hash_main, "Type de mémoire")


    # Informations sur le(s) disque(s) dur(s)
    hash_disk[:disk_name] = extract_from_hash(hash_main, "Configuration disque(s)")
    hash_disk[:disk_main] = extract_from_hash(hash_main, "Disque dur")
    hash_disk[:disk_secondary] = extract_from_hash(hash_main, "Disque secondaire")
    hash_disk[:disk_secondary] = "Non" if hash_disk[:disk_secondary].nil?
    hash_disk[:disk_number] = extract_from_hash(hash_main, "Nombre de disques")
    hash_disk[:disk_number_max] = extract_from_hash(hash_main, "Nombre de disques max")
    hash_disk[:disk_type] = extract_from_hash(hash_main, "Type de Disque")
    hash_disk[:disk_interface] = extract_from_hash(hash_main, "Interface du disque dur")


    # Informations sur l'écran
    hash_screen[:screen_type] = extract_from_hash(hash_main, "Type d'écran")
    hash_screen[:screen_resolution] = extract_from_hash(hash_main, "Résolution Max")
    hash_screen[:screen_refresh_rate] = extract_from_hash(hash_main, "Taux de rafraîchissement")
    hash_screen[:screen_size] = extract_from_hash(hash_main, "Taille de l'écran")
    hash_screen[:screen_format] = extract_from_hash(hash_main, "Format de l'écran")


    # Informations sur le clavier
    hash_keyboard[:keyboard_type] = extract_from_hash(hash_main, "Norme du clavier")
    hash_keyboard[:keyboard_numpad] = extract_from_hash(hash_main, "Pavé numérique") == "Oui" ? true : false
    hash_keyboard[:keyboard_light] = extract_from_hash(hash_main, "Clavier rétroéclairé") == "Oui" ? true : false


    # Informations sur la carte graphique
    hash_graphics[:gpu_name] = extract_from_hash(hash_main, "Chipset graphique")


    #On regroupe toutes les infos dans un hash
    pc[:additionnal_informations] = hash_main
    pc[:os] = hash_os
    pc[:cpu] = hash_cpu
    pc[:memory] = hash_memory
    pc[:disk] = hash_disk
    pc[:screen] = hash_screen
    pc[:keyboard] = hash_keyboard
    pc[:network] = extract_from_hash(hash_main, 'Norme(s) réseau')
    pc[:gpu] = hash_graphics
    pc[:webcam] = (extract_from_hash(hash_main, "Webcam").match(/oui/i) ? true : false) rescue nil
    pc[:main_photo] = page.search('div.c-product__thumb img').first[:src] rescue nil
    pc[:connector_available] = extract_from_hash(hash_main, 'Connecteur(s) disponible(s)')

    pc[:weight] = (extract_from_hash(hash_main, "Poids").gsub(",",".").to_f) rescue nil
    pc[:width] = (extract_from_hash(hash_main, "Largeur").gsub(",",".").to_f) rescue nil
    pc[:length] = (extract_from_hash(hash_main, "Profondeur").gsub(",",".").to_f) rescue nil
    pc[:height] = (extract_from_hash(hash_main, "Epaisseur Arrière").gsub(",",".").to_f) rescue nil

    # Objet final pour le Computer
    Computer.insert_pc(pc, 5)

  end


  # Extraire une valeur d'un hash
  def self.extract_from_hash hash, key
    ret_value = ''
    if key.size > 0 && hash[key]
      ret_value = hash[key]
      hash.delete(key)
      return ret_value
    end
  end
end
