newer_than_1_8 = RUBY_VERSION.split(".").map(&:to_i).zip([1,8]).any? { |a, b| a > b }
csv_class_name = newer_than_1_8 ? "CSV" : "FasterCSV"
begin
  require csv_class_name.downcase
rescue LoadError
  puts "WARN: #{csv_class_name} not loaded"
end

module KSnippet
  mattr_accessor :safety
  @@safety = true
  @@loaded = false

  def self.load
    return false if @@loaded

    ::Card.class_eval { extend CoreExt::ActiveRecord::Card } if defined?(::Card)
    ::Merchant.class_eval { include CoreExt::ActiveRecord::Merchant } if defined?(::Merchant)
    ::MallDistrict.class_eval { include KSnippet::CoreExt::ActiveRecord::MallDistrict } if defined?(::MallDistrict)

    ::ActiveRecord::Base.class_eval { extend CoreExt::ActiveRecord::Base }
    ::Object.class_eval { include CoreExt::Object }
    ::Array.class_eval { include CoreExt::Array }

    ::Module.class_eval { include CoreExt::Module::RetroactiveModuleInclusion }

    ::Enumerable.module_eval { retroactively_include CoreExt::Enumerable }

    return @@loaded = true
  end

  def self.carefully(&block)
    if @@safety then raise "safety's on" end
    ret = nil
    ActiveRecord::Base.transaction do
      ret = yield
    end
    @@safety = true
    return ret
  end

  def self.invalid_mall_cards
    conds = { :conditions => { :shopping_cart_id => nil }, :include => :cards }
    unimported_txns = MallTransaction.confirmed.all(conds)

    unimported_cards = unimported_txns.reject(&:bhn_test_transaction?).map(&:cards).flatten.select(&:pending?).reject(&:bhn_test_card?)
    invalid_cards = unimported_cards.reject(&:valid?)

    unhandled = []
    num_pin_group = invalid_cards.group_by { |c| [c.number, c.pin] }
    num_pin_group.each do |(num, pin), cards|
      card_txns = cards.map { |c| [c, c.mall_transaction_id] }.sort_by(&:last)
      one_to_one_relationship = cards.uniq.size == card_txns.map(&:last).uniq.size
      if one_to_one_relationship
        txns_to_cancel = MallTransaction.find(card_txns[0..-2].map(&:last))
        txns_to_cancel.each { |txn| txn.cancel_with_duplicate_cards!(User.kc, "cancelling duplicate mall transactions") }
      else
        unhandled << cards
      end
    end

    return unhandled
  end

  def self.to_csv(obj_or_hash_matrix, opt={ :col_sep => "\t" })
    args = obj_or_hash_matrix.group_by do |arg|
      is_hashlike = arg.respond_to?(:keys) && arg.respond_to?(:[])
      is_hashlike ? :hashes : :objs
    end

    hashes = args[:hashes].inject(&:merge)
    objs = args[:objs]

    obj_headers = [nil] * enums.map(&:size).max
    hash_headers = hashes.map(&:keys).uniq

    FasterCSV.generate do |csv|
      csv << enums_header + hashes_header

    end


    hashes = args.select { |h| h.respond_to?(:keys) && h.respond_to?(:[]) }


    arr = Array(hashes_lists_or_objs)
    if arr.all? { |hash| hash.respond_to?(:keys) }
      hashes_to_csv(arr, opt)
    elsif arr.all? .class < Enumerable
      lists_to_csv(arr, opt)
    else
      objs_to_csv(arr, opt)
    end
  end

  def self.hashes_to_csv(hashes, opt={})
    keys = opt[:keys] || hashes.map(&:keys).flatten.uniq
    opt.delete(:keys)

    FasterCSV.generate(opt) do |csv|
      csv << keys
      hashes.each do |hash|
        csv << keys.map do |key|
          hash[key]
        end
      end
    end
  end

  def self.lists_to_csv(lists, opt={})
    FasterCSV.generate(opt) { |csv| csv << lists }
  end

  def self.objs_to_csv(objs, opt={})
    methods = objs.shift.map(&:to_s)
    FasterCSV.generate(opt) do |csv|
      csv << methods
      objs.each { |obj| csv << methods.map { |method| obj.send(method) } }
    end
  end

  def self.pbcopy(copy_to_clipboard)
    IO.popen('pbcopy', 'w') { |f| f << copy_to_clipboard.to_s }
    copy_to_clipboard.to_s
  end

  def self.pbpaste
    `pbpaste`
  end

  def self.dpg_proxy(host)
    `ssh -Nn -lcapistrano -p18639 -D 9999 #{host}`
    #command = "ssh -M -S /tmp/proxy9978.ctl -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -f -N -D9999 -lcapistrano -p18639 #{host}"
  end

  module CoreExt
    module Object
      def self.included(base)
        base.extend(ClassMethods)
      end

      def as(&converter)
        if !block_given? then return self end
        yield self
      end

      module ClassMethods
        def eigenclass
          class << self
            self
          end
        end
      end
    end

    module Array
      def self.included(base)
        base.alias_method_chain :uniq, :block
      end

      def uniq_with_block(&key_func)
        if !block_given? then return self.uniq_without_block end
        self.group_by { |e| yield(e) }.map { |k, elems| elems.first }
      end

      def to_h
        Hash[self]
      end
    end

    module Enumerable
      def histogram(&key_func)
        self.inject({}) do |hist, e|
          key = block_given? ? yield(e) : e
          hist[key] = hist.fetch(key) { 0 } + 1
          hist
        end
      end
    end

    module ActiveRecord
      module Base
        def last_created_at_before(target_time, opt={}, range=nil, limit=nil)
          range ||= self.with_exclusive_scope do
            1..(self.last.id)
          end

          puts "range: #{range.inspect}" if opt[:verbose]

          limit ||= (Math.log(range.last) / Math.log(2))
          if limit <= 0 then return nil end

          get_up_to_id = lambda do |id|
            self.with_exclusive_scope do
              self.first(:conditions => "id <= #{id}", :order => "id desc") || self.first
            end
          end

          if range.last - range.first <= 10
            return self.all(:conditions => ["? <= id and id <= ?", range.first, range.last], :order => "created_at desc").find { |rec| rec.created_at <= target_time }
          end

          first_value, last_value = [range.first, range.last].map { |id| get_up_to_id[id].created_at }

          puts "values: #{first_value} :: #{last_value}" if opt[:verbose]

          midpoint = ((range.first + range.last) / 2).to_i
          midpoint_value = self.find(midpoint).created_at

          new_range = if target_time < midpoint_value
                        puts "going left, #{midpoint - range.first}" if opt[:verbose]
                        range.first..midpoint
                      else
                        puts "going right, #{range.last - midpoint}" if opt[:verbose]
                        midpoint..range.last
                      end

          return self.last_created_at_before(target_time, opt, new_range, limit - 1)
        end

        def created_between(start, finish, &block)
          if !block_given? then return end

          block.call(self.last_created_at_before(start), self.last_created_at_before(finish))
        end

        def indexes
          self.connection.indexes(self.table_name).map(&:columns)
        end

        def auto_increment
          #self.connection.select_all("show table status like #{self.table_name}")["Auto_increment"]
          self.connection.select_value("select auto_increment from information_schema.tables where table_name = '#{self.table_name}';").to_i
        end

        def auto_increment=(index)
          KSnippet.carefully do
            safe_index = Integer(index)
            self.connection.execute("alter table #{self.table_name} auto_increment = #{safe_index};")
          end
        end
      end

      module Card
        def find_by_hash(query_type, num_hash, pin_hash=nil)
          raise "query_type must be :first, :last, or :all" if ![:first, :last, :all].include?(query_type)
          where = [ "SHA1(number) = ?", pin_hash && "SHA1(pin) = ?" ].compact.join(" AND ")
          conditions = { :conditions => [where, num_hash, pin_hash].compact }
          self.with_exclusive_scope do
            case query_type
              when :first then self.first(conditions)
              when :last  then self.last(conditions)
              when :all   then self.all(conditions)
              else "query_type must be :first, :last, or :all"
            end
          end
        end

        def first_by_hash(num_hash, pin_hash=nil)
          self.find_by_hash(:first, num_hash, pin_hash)
        end

        def last_by_hash(num_hash, pin_hash=nil)
          self.find_by_hash(:last, num_hash, pin_hash)
        end

        def all_by_hash(num_hash, pin_hash=nil)
          self.find_by_hash(:all, num_hash, pin_hash)
        end
      end

      module Merchant
        def self.included(base)
          base.extend(ClassMethods)
        end

        # normalizes merchant name into camel case
        def canonical_title
          return I18n.transliterate(self.name).titleize.sub(/^\d+/, "").gsub(/[\s,.'()\-\/!\?+]/, "").gsub(/&/, "And")
        end

        module ClassMethods
          # fuzzily finds from a given identifier
          # attempts matching in order of 'exactness':
          #   * Merchant class
          #   * default #find method
          #   * name string match
          #   * name substring match
          #   * canonical title substring match
          # string matching is case-insensitive
          def ffind(identifier)
            record ||= if identifier.is_a?(self.class) then identifier end

            record ||= begin
                         self.find(identifier)
                       rescue ::ActiveRecord::RecordNotFound
                       end

            search_name = identifier.is_a?(Symbol) ? identifier.to_s.gsub("_", " ") : identifier.to_s
            record ||= self.find_by_name(search_name)

            record ||= self.first(:conditions => "name like '%#{search_name}%'", :order => "length(name)")

            record ||= self.all.select do |r|
              r.canonical_title.underscore.include?(search_name.downcase)
            end.sort_by { |r| r.canonical_title.underscore.length }.first

            if record.nil? then raise ArgumentError, "#{self} '#{identifier.inspect}' not found" end
            return record
          end
        end
      end

      module MallDistrict
        def change_id(new_id)
          KSnippet.carefully do
            new_id = Integer(new_id)
            if self.class.find_by_id(new_id).present? then raise "MallDistrict #{new_id} already exists" end
            old_id = self.id

            locations = self.mall_locations
            dynamic_pricing_adjustments = self.dynamic_pricing_adjustments
            mall_sub_districts = self.mall_sub_districts

            self.class.update_all("id = #{new_id}", "id = #{old_id}")

            (locations + dynamic_pricing_adjustments + mall_sub_districts).each do |obj|
              obj.mall_district_id = new_id
              obj.save!
            end

            old_id
          end
        end
      end
    end

    module Module
      # https://github.com/adrianomitre/retroactive_module_inclusion
      module RetroactiveModuleInclusion
        # Includes +mod+ retroactively, i.e., extending to all classes and modules which
        # had included +self+ _beforehand_.
        #
        # @example Retroactively include a module in Enumerable.
        #
        #   module Stats
        #     def mean
        #       inject(&:+) / count.to_f
        #     end
        #   end
        #
        #   Enumerable.retroactively_include Stats
        #
        #   (1..2).mean  #=>  1.5
        #
        # @return self
        #
        def retroactively_include(mod)
          raise TypeError, "wrong argument type #{mod.class} (expected Module)" unless mod.is_a? ::Module # ::Module would in general be equivalent to Object::Module and simply Module would mean CoreExt::Module in this context

          pseudo_descendants.each do |pd|
            pd.module_eval { include mod }
          end

          self
        end

        private

        # @return [Array] All modules and classes which have self in its
        #                 ancestors tree, including self itself.
        #
        # JRuby (at least up to version 1.5.6) has ObjectSpace disabled by
        # default, thus it might have to be temporarily enabled and then
        # restored. Reference: {ObjectSpace: to have or not to have}[http://ola-bini.blogspot.com/2007/07/objectspace-to-have-or-not-to-have.html].
        #
        def pseudo_descendants
          prev_jruby_objectspace_state = nil # only for scope reasons
          if defined?(RUBY_DESCRIPTION) && RUBY_DESCRIPTION =~ /jruby/i
            require 'jruby'
            prev_jruby_objectspace_state = JRuby.objectspace
            JRuby.objectspace = true
          end
          result = ObjectSpace.each_object(::Module).select {|m| m <= self } # equiv. to "m.include?(self) || m == self"
          if defined?(RUBY_DESCRIPTION) && RUBY_DESCRIPTION =~ /jruby/i
            JRuby.objectspace = prev_jruby_objectspace_state
          end
          result
        end
      end
    end
  end
end
