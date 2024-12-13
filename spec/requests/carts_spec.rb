require 'rails_helper'

RSpec.describe "/carts", type: :request do
  before do
    Cart.destroy_all
    allow_any_instance_of(CartsController).to receive(:session).and_return(cart_id: cart.id)
  end

  let(:cart) { Cart.create! }
  let(:product) { Product.create!(name: "Test Product", price: 10.0) }
  let(:new_product) { Product.create!(name: "Another Product", price: 20.0) }

  describe "POST /cart" do
    subject do
      post "/cart", params: { product_id: new_product.id, quantity: 1 }, as: :json
    end

    context "when adding a new product" do
      it "adds the product to the cart" do
        cart.reload
        expect { subject }.to change { cart.cart_items.count }.by(1)
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(cart.id)
        expect(json_response["products"].last["id"]).to eq(new_product.id)
      end
    end

    context "when the cart already exists" do
      let(:cart) { Cart.create!(total_price: 0) }

      subject do
        post "/cart", params: { product_id: product.id, quantity: 3 }, as: :json
      end

      it "adds the product to the existing cart" do
        expect { subject }.to change { cart.cart_items.count }.by(1)
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["products"].size).to eq(1)
        expect(json_response["total_price"]).to eq(30.0)
      end
    end

    context "when the product does not exist" do
      subject do
        post "/cart", params: { product_id: 9999, quantity: 2 }, as: :json
      end

      it "returns an error" do
        subject
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Product not found")
      end
    end

    context "when the quantity is invalid" do
      subject do
        post "/cart", params: { product_id: product.id, quantity: -1 }, as: :json
      end

      it "returns an error" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Quantity must be greater than 0")
      end
    end
  end


  describe "POST /add_items" do
    let(:cart) { Cart.create }
    let(:product) { Product.create(name: "Test Product", price: 10.0) }
    let!(:cart_item) { CartItem.create(cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      subject do
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end
    end
  end
end
