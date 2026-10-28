store_base_url = ENV.fetch("STORE_BASE_URL", "http://localhost:3000")

restaurants = [
  { id: 1, code: "PROV", name: "Niu Foods Providencia" },
  { id: 2, code: "LCON", name: "Niu Foods Las Condes" },
  { id: 3, code: "NUNO", name: "Niu Foods Ñuñoa" }
]

products = [
  { id: 1, sku: "SKU-001", name: "Niu Roll Salmón", price: 8990 },
  { id: 2, sku: "SKU-002", name: "California Ebi", price: 7490 },
  { id: 3, sku: "SKU-003", name: "Avocado Roll", price: 6990 },
  { id: 4, sku: "SKU-004", name: "Nigiri Salmón x2", price: 3990 },
  { id: 5, sku: "SKU-005", name: "Gyozas de Pollo x5", price: 4490 },
  { id: 6, sku: "SKU-006", name: "Edamame", price: 3290 },
  { id: 7, sku: "SKU-007", name: "Bowl Salmón Teriyaki", price: 9990 },
  { id: 8, sku: "SKU-008", name: "Bowl Pollo Teriyaki", price: 8990 },
  { id: 9, sku: "SKU-009", name: "Bebida 350 ml", price: 1990 },
  { id: 10, sku: "SKU-010", name: "Agua Mineral 500 ml", price: 1590 }
]

restaurants.each do |attrs|
  Restaurant.find_or_initialize_by(id: attrs[:id])
            .update!(attrs.merge(dispatch_url: "#{store_base_url}/stores/#{attrs[:code]}/orders"))
end

products.each do |attrs|
  Product.find_or_initialize_by(id: attrs[:id]).update!(attrs)
end

%w[restaurants products].each do |table|
  ActiveRecord::Base.connection.reset_pk_sequence!(table)
end

puts "Seeds: #{Restaurant.count} restaurantes, #{Product.count} productos"
