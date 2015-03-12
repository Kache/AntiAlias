require 'fastercsv'

mts = MallTransaction.all(:conditions => ["credit_card_hash is not null and state = 'confirmed' and created_at > ? and created_at < ?", Time.parse("12/01/2014"), Time.parse("12/04/2014")])
mt_csv = FasterCSV.generate do |csv|
  csv << mts.first.attributes.sort.map{|a| a.first}
  mts.each do |mt|
    line = []
    mt.attributes.sort.each do |k,v|
      # if k != "created_at" && k != "updated_at" && k != "user_id"
      #   line << v
      # end
      line << v
    end
    csv << line
  end
end

File.open("/tmp/mt_dump.csv", "w") do |f|
  f.puts(mt_csv)
end



cardpool_user_ids = User.find(:all, :conditions => "RIGHT(email, 13) = '@cardpool.com'").map { |u| u.id.to_i }
cardpool_user_ids.uniq!

ales_csv = FasterCSV.generate do |csv|
  csv << ["tmx_device_id", "tmx_device_id", "phone_number", "email", "credit_card_hash", "user_id"]
  start_ale_id = 268926294
  end_ale_id = 275453002

  while (start_ale_id <= end_ale_id)
    ales_to_expand = SiteShared::ActionLogEntry.find(
            :all, :conditions => ["id > #{start_ale_id} and user_id is not null"],
            :include => [:active_user, :user, {:shopping_cart => [:billing_address, :order_transactions]}],
            :limit => 10000)
    start_ale_id += 10000

    ales_to_expand.each do |ale|
      user_id = ale.user_id
      if cardpool_user_ids.include?(user_id)
        next
      end

      if ale.shopping_cart.present?
        if ale.shopping_cart.verified_address.present?
          phone = ale.shopping_cart.verified_address.phone_number
        end
        sc_tmx = ale.shopping_cart.tmx_device_id
        transactions = ale.shopping_cart.order_transactions
        cch = transactions.length > 0 ? transactions.last.credit_card_hash : nil
      end

      if ale.active_user
        email = ale.active_user.email
      end
      if ale.user
        if ale.user.action_log_entry == ale
          user_tmx = ale.user.tmx_device_id
        end
      end
      
      line = [sc_tmx, user_tmx, phone, email, cch, user_id]
      if line.compact.count == 1
        next
      end
      csv << line
    end
  end
end

File.open("/tmp/ales_dump.csv", "w") do |f|
  f.puts(ales_csv)
end
