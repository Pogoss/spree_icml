class ExportIcml

  def self.export
    doc = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
      xml.yml_catalog(date: Time.now.strftime('%F %T')) {
        xml.shop {
          shop_name = Spree::Store.first && Spree::Store.first.name
          shop_url = Spree::Store.first.url
          xml.name(shop_name)
          xml.company(shop_name)
          xml.categories {
            Spree::Taxon.find_each do |t|
              cat_attributes = {id: t.id}
              cat_attributes[:parentId] = t.parent_id if t.parent_id
              xml.category(cat_attributes).text(t.name)
            end
          }
          xml.offers {
            Spree::Variant.find_each do |v|
              next unless v.options.present?
              xml.offer(id: v.id, product_id: v.product_id, quantity: v.stock_items.sum(:count_on_hand)){
                xml.url.text("#{shop_url}/products/#{v.product_id}/#{v.options[:color] && v.options[:color][:slug]}")
                xml.price.text(v.price)
                xml.purchasePrice.text(v.cost_price || v.price)
                xml.categoryId.text(v.product && v.product.taxons.first && v.product.taxons.first.id)
                image = nil
                if v.images.present?
                  image = shop_url + v.images.first.attachment.url
                elsif v.product && v.product.images.present?
                  image = shop_url + v.product.images.first.attachment.url
                end
                xml.picture.text(image) if image
                xml.name.text("#{v.name} #{v.options[:color] && v.options[:color][:slug]} #{v.options[:size] && v.options[:size][:name]}")
                xml.productName.text(v.name)
                # xml.param(name: 'артикул', code: 'article').text(v.product.sku) if v.product.sku.present?
                v.options.each do |option, values|
                  if option == :color
                    xml.param(name: option.to_s, code: option.to_s).text(values[:slug])
                  else
                    xml.param(name: option.to_s, code: option.to_s).text(values[:name])
                  end
                end
                xml.vendor.text(shop_name)
                xml.unit(code: 'pcs', name: 'штука', sym: 'шт.')
              }
            end
          }
        }
      }
    end
    File.write('public/icml_export.xml', doc.to_xml)
  end


end