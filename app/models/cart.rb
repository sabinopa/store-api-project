class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items


  def add_item(product_id, quantity)
    product = find_product(product_id)
    return false unless product

    return false unless valid_quantity?(quantity)

    cart_item = cart_items.find_or_initialize_by(product_id: product.id)
    cart_item.quantity += quantity.to_i
    cart_item.save!

    update_total_price
    true
  end

  private
  
  def find_product(product_id)
    product = Product.find_by(id: product_id)
    unless product
      errors.add(:base, "Product not found")
      return false
    end
    product
  end

  def valid_quantity?(quantity)
    if quantity.to_i <= 0
      errors.add(:base, "Quantity must be greater than 0")
      return false
    end
    true
  end

  def update_total_price
    self.total_price = cart_items.sum { |item| item.product.price * item.quantity }
    save!
  end
end
