require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let!(:cart) { create(:cart) }
  let!(:product) { create(:product, name: "Test Product", price: 10.0) }
  let!(:new_product) { create(:product, name: "New Product", price: 20.0) }

  before do
    allow_any_instance_of(CartsController).to receive(:session).and_return(cart_id: cart.id)
  end

  describe "GET /cart" do
    context "when the cart is empty" do
      it "returns an empty cart with total_price 0.0" do
        get "/cart", as: :json
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["products"]).to be_empty
        expect(json_response["total_price"]).to eq(0.0)
      end
    end
  end

  describe "POST /cart" do
    context "when adding a new product" do
      subject { post "/cart", params: { product_id: product.id, quantity: 1 }, as: :json }

      it "adds the product to the cart" do
        expect { subject }.to change { cart.cart_items.count }.by(1)
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(cart.id)
        expect(json_response["products"].last["id"]).to eq(product.id)
        expect(json_response["total_price"]).to eq(10.0)
      end
    end

    context "when the product does not exist" do
      subject { post "/cart", params: { product_id: 9999, quantity: 2 }, as: :json }

      it "returns an error" do
        subject
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Product not found")
      end
    end

    context "when the quantity is invalid" do
      subject { post "/cart", params: { product_id: product.id, quantity: -1 }, as: :json }

      it "returns an error" do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Quantity must be greater than 0")
      end
    end
  end

  describe "POST /add_items" do
    context 'when the product already is in the cart' do
      before do
        create(:cart_item, cart: cart, product: product, quantity: 2)
      end

      it 'updates the quantity of the existing item in the cart' do
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:ok)
        expect(cart.cart_items.first.reload.quantity).to eq(3)
      end

      it 'handles multiple consecutive requests' do
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
        expect(cart.cart_items.first.reload.quantity).to eq(4)
      end
    end
  end
end
