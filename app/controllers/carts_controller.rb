class CartsController < ApplicationController
  before_action :set_cart

  def show
    render json: format_cart_response(@cart), status: :ok
  end

  def create
    if @cart.add_item(params[:product_id], params[:quantity])
      render json: format_cart_response(@cart), status: :ok
    elsif @cart.errors[:base].include?("Product not found")
      render json: { error: "Product not found" }, status: :not_found
    else
      render json: { error: @cart.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def add_item
    if @cart.add_item(params[:product_id], params[:quantity])
      render json: format_cart_response(@cart), status: :ok
    else
      render json: { error: @cart.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def set_cart
    @cart = Cart.find_by(id: session[:cart_id])
    unless @cart
      @cart = Cart.create!(total_price: 0.0)
      session[:cart_id] = @cart.id
    end
  end

  def format_cart_response(cart)
    {
      id: cart.id,
      products: cart.cart_items.map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.product.price.to_f,
          total_price: (item.product.price * item.quantity).to_f
        }
      end,
      total_price: cart.total_price.to_f
    }
  end
end
