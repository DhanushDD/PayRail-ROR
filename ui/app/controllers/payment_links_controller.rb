class PaymentLinksController < ApplicationController
  before_action :authenticate_user!, except: [:show, :pay]

  def index
    @links = current_user.payment_links.order(created_at: :desc)
    @wallet = current_user.primary_wallet
  end

  def create
    wallet = current_user.primary_wallet
    amount_cents = (params[:amount].to_f * 100).round

    link = current_user.payment_links.create!(
      wallet: wallet,
      title: params[:title].presence || "Payment Request",
      description: params[:description],
      amount_cents: amount_cents,
      currency: wallet.currency
    )

    flash[:notice] = "Payment link '#{link.title}' generated successfully!"
    redirect_to payment_links_path
  end

  def show
    @link = PaymentLink.find_by!(link_token: params[:token])
  end

  def pay
    @link = PaymentLink.find_by!(link_token: params[:token])

    if @link.status != "active"
      flash[:alert] = "This payment link is no longer active."
      return redirect_to checkout_path(@link.link_token)
    end

    payer_name = params[:payer_name].presence || "Guest Customer"
    recipient_wallet = @link.wallet

    ActiveRecord::Base.transaction do
      recipient_wallet.lock!
      new_balance = recipient_wallet.balance_cents + @link.amount_cents
      recipient_wallet.update_columns(balance_cents: new_balance, updated_at: Time.current)

      transfer = Transfer.create!(
        sender_wallet_id: nil,
        recipient_wallet: recipient_wallet,
        amount_cents: @link.amount_cents,
        fee_cents: 0,
        currency: @link.currency,
        transfer_type: "payment_link",
        status: "completed",
        category: "shopping",
        description: "Checkout: #{@link.title} (Paid by #{payer_name})",
        metadata: { link_token: @link.link_token, payer_name: payer_name }
      )

      LedgerEntry.create!(
        transfer: transfer,
        wallet: recipient_wallet,
        entry_type: "credit",
        amount_cents: @link.amount_cents,
        balance_after_cents: new_balance,
        description: "Payment Link Credit: #{@link.title}"
      )

      @link.update!(status: "claimed", claimed_by_name: payer_name)
    end

    flash[:notice] = "Payment of #{@link.formatted_amount} processed successfully! Thank you, #{payer_name}."
    redirect_to checkout_path(@link.link_token)
  end
end
