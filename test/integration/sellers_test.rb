require "#{File.dirname(__FILE__)}/../test_helper"

class SellersTest < ActionController::IntegrationTest
  fixtures :people, :obligations, :roles, :exchanges, :addresses, :barcodes, :books, :sellers, :orders

  def setup
    Seller.rebuild_index
  end

  # Permit

  def test_should_deny_all_if_not_authenticated
    new_session do |guest|
      guest.fails_authentication sellers_path, seller_path(sellers(:jack)), new_seller_path, edit_seller_path(sellers(:jack)), contract_seller_path(sellers(:jack))
    end
  end

  def test_should_allow_all_if_authenticated
    new_session_as(:jack) do |jack|
      jack.goes_to sellers_path, 'sellers/index'
      jack.goes_to seller_path(sellers(:jack)), 'sellers/show'
      jack.goes_to new_seller_path, 'sellers/new'
      jack.goes_to edit_seller_path(sellers(:jack)), 'sellers/edit'
      jack.goes_to contract_seller_path(sellers(:jack)), 'sellers/contract'
    end
  end

  # Actions

  def test_index
    new_session_as(:jack) do |jack|
      jack.goes_to sellers_path, 'sellers/index'
      jack.assert_not_assigns :sellers
      jack.assert_select 'a.clear', false
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption', false
    end
  end

  def test_index_with_no_results
    new_session_as(:jack) do |jack|
      jack.goes_to sellers_path(:q => 'not_valid'), 'sellers/index'
      jack.assert_assigns :sellers
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty'
      jack.assert_select 'caption', false
      jack.assert_equal 0, jack.assigns(:sellers).size
    end
  end

  def test_index_with_some_results
    new_session_as(:jack) do |jack|
      jack.goes_to sellers_path(:q => 'example.com'), 'sellers/index'
      jack.assert_assigns :sellers
      jack.assert_select 'a.clear'
      jack.assert_select 'h3.empty', false
      jack.assert_select 'caption'
      jack.assert_equal_with_permutation [ sellers(:jack), sellers(:jill), sellers(:joe) ], jack.assigns(:sellers)
    end
  end

  def test_index_with_unique_result
    new_session_as(:jack) do |jack|
      jack.get sellers_path(:q => 'jack')
      jack.is_redirected_to 'sellers/show'
    end
  end

  def test_show_with_manager
    new_session_as(:jack) do |jack|
      jack.goes_to seller_path(sellers(:jack)), 'sellers/show'
      jack.assert_assigns :seller, :books
      jack.assert_equal sellers(:jack), jack.assigns(:seller)
      jack.assert_equal_with_permutation [ books(:book_reclaimed), books(:ordered), books(:instock), books(:money_reclaimed), books(:held_reclaimed), books(:sold), books(:lost), books(:held) ], jack.assigns(:books)
    end
  end

  def test_show_with_non_manager
    new_session_as(:joe) do |joe|
      joe.goes_to seller_path(sellers(:jill)), 'sellers/show'
      joe.assert_assigns :seller, :books
      joe.assert_equal sellers(:jill), joe.assigns(:seller)
      joe.assert_equal 0, joe.assigns(:books).size
    end
  end

  def test_new
    new_session_as(:jack) do |jack|
      jack.goes_to new_seller_path, 'sellers/new'
      jack.assert_assigns :seller
    end
  end

  def test_create
    new_session_as(:jack) do |jack|
      jack.post sellers_path, :seller => valid_record
      jack.assert_flash :notice
      jack.is_redirected_to 'sellers/show'
    end
  end

  def test_create_and_add_another
    new_session_as(:jack) do |jack|
      jack.goes_to new_seller_path, 'sellers/new'
      jack.post sellers_path, :seller => valid_record, :add_a_book => 'yes'
      jack.assert_flash :notice
      jack.is_redirected_to 'books/new'
    end
  end

  def test_edit
    new_session_as(:jack) do |jack|
      jack.goes_to edit_seller_path(sellers(:jack)), 'sellers/edit'
      jack.assert_assigns :seller
      jack.assert_equal sellers(:jack), jack.assigns(:seller)
    end
  end

  def test_update
    new_session_as(:jack) do |jack|
      assert_change sellers(:jack), :name, :telephone, :email_address do
        jack.put seller_path(sellers(:jack)), :seller => valid_record
        jack.assert_flash :notice
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_contract_with_welcome_email_not_sent
    new_session_as(:jack) do |jack|
      assert_change sellers(:jack), :contract_printed_at do
        assert_change sellers(:jack), :welcome_email_sent_at do
          jack.goes_to contract_seller_path(sellers(:jack)), 'sellers/contract'
          jack.assert_assigns :seller, :books
          jack.assert_equal sellers(:jack), jack.assigns(:seller)
          jack.assert_equal_with_permutation [ books(:instock), books(:sold), books(:lost), books(:held), books(:ordered) ], jack.assigns(:books)
        end
      end
    end
  end

  def test_contract_with_welcome_email_sent
    new_session_as(:jack) do |jack|
      assert_change sellers(:jill), :contract_printed_at do
        assert_no_change sellers(:jill), :welcome_email_sent_at do
          jack.goes_to contract_seller_path(sellers(:jill)), 'sellers/contract'
          jack.assert_assigns :seller, :books
          jack.assert_equal sellers(:jill), jack.assigns(:seller)
          jack.assert_equal [], jack.assigns(:books)
        end
      end
    end
  end

  def test_contract_with_no_email_address
    new_session_as(:jack) do |jack|
      assert_change sellers(:bob), :contract_printed_at do
        assert_no_change sellers(:bob), :welcome_email_sent_at do
          jack.goes_to contract_seller_path(sellers(:bob)), 'sellers/contract'
          jack.assert_assigns :seller, :books
          jack.assert_equal sellers(:bob), jack.assigns(:seller)
          jack.assert_equal_with_permutation [ books(:bob_instock), books(:bob_sold), books(:bob_lost), books(:bob_ordered) ], jack.assigns(:books)
        end
      end
    end
  end

  def test_pay_service_fee_with_service_fee_not_paid
    new_session_as(:jack) do |jack|
      assert_change sellers(:jack), :paid_service_fee_at do
        jack.goes_to seller_path(sellers(:jack)), 'sellers/show'
        jack.put pay_service_fee_seller_path(sellers(:jack))
        jack.assert_flash :notice
        jack.is_redirected_to 'sellers/show'
      end
    end
  end
  def test_pay_service_fee_with_service_fee_paid
    new_session_as(:jack) do |jack|
      assert_no_change sellers(:jill), :paid_service_fee_at do
        jack.goes_to seller_path(sellers(:jill)), 'sellers/show'
        jack.put pay_service_fee_seller_path(sellers(:jill))
        jack.assert_flash :notice
        jack.is_redirected_to 'sellers/show'
      end
    end
  end
  def test_unpay_service_fee_with_service_fee_paid
    new_session_as(:jack) do |jack|
      assert_change sellers(:jill), :paid_service_fee_at do
        jack.goes_to seller_path(sellers(:jill)), 'sellers/show'
        jack.put unpay_service_fee_seller_path(sellers(:jill))
        jack.assert_flash :notice
        jack.is_redirected_to 'sellers/show'
      end
    end
  end
  def test_unpay_service_fee_with_service_fee_not_paid
    new_session_as(:jack) do |jack|
      assert_no_change sellers(:jack), :paid_service_fee_at do
        jack.goes_to seller_path(sellers(:jack)), 'sellers/show'
        jack.put unpay_service_fee_seller_path(sellers(:jack))
        jack.assert_flash :notice
        jack.is_redirected_to 'sellers/show'
      end
    end
  end

  def test_destroy_with_books
    new_session_as(:jack) do |jack|
      assert_no_difference 'Seller.count' do
        jack.delete seller_path(sellers(:jack))
        jack.assert_flash :error
        jack.is_redirected_to 'sellers/index'
      end
    end
  end

  def test_destroy_without_books
    new_session_as(:jack) do |jack|
      assert_difference 'Seller.count', -1 do
        jack.delete seller_path(sellers(:jill))
        jack.assert_flash :notice
        jack.is_redirected_to 'sellers/index'
      end
    end
  end

  protected
    def valid_record(options = {})
      { :name => 'James', 
        :telephone => '5557779999', 
        :email_address => 'james@example.com', 
      }.merge(options)
    end  


end
