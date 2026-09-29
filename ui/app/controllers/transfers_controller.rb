class TransfersController < ApplicationController
  before_action :authenticate_user!

  def new
    @wallet = current_user.primary_wallet
    @peers = User.where.not(id: current_user.id).limit(8)
    @preset_recipient = params[:recipient]
  end

  def create
    @wallet = current_user.primary_wallet
    recipient_input = params[:recipient].to_s.strip.downcase
    clean_tag = recipient_input.delete_prefix("$")

    recipient_user = User.where("LOWER(email) = :q OR LOWER(payrail_tag) = :tag", q: recipient_input, tag: "$#{clean_tag}").first

    unless recipient_user
      flash[:alert] = "Recipient '#{params[:recipient]}' was not found on PayRail."
      return redirect_to new_transfer_path
    end

    recipient_wallet = recipient_user.primary_wallet
    unless recipient_wallet
      flash[:alert] = "Recipient does not have an active wallet."
      return redirect_to new_transfer_path
    end

    amount_cents = (params[:amount].to_f * 100).round

    result = Transfers::ExecuteService.call(
      sender_wallet: @wallet,
      recipient_wallet: recipient_wallet,
      amount_cents: amount_cents,
      category: params[:category] || "transfer",
      description: params[:description].presence || "Transfer to #{recipient_user.payrail_tag}",
      idempotency_key: "web_ui_#{SecureRandom.hex(12)}"
    )

    if result.success?
      flash[:notice] = "Transfer of #{result.transfer.formatted_amount} to #{recipient_user.name} completed instantly!"
      redirect_to transfer_path(result.transfer.reference_id)
    else
      flash[:alert] = result.error_message
      redirect_to new_transfer_path
    end
  end

  def show
    wallet_ids = current_user.wallets.pluck(:id)
    @transfer = Transfer.where("sender_wallet_id IN (:ids) OR recipient_wallet_id IN (:ids)", ids: wallet_ids)
                        .find_by!(reference_id: params[:id])

    @ledger_entries = @transfer.ledger_entries.includes(:wallet)
  end

  def lookup
    query = params[:q].to_s.strip.downcase
    tag = query.delete_prefix("$")

    users = User.where("LOWER(email) LIKE :q OR LOWER(payrail_tag) LIKE :tag OR LOWER(name) LIKE :q", q: "%#{query}%", tag: "%#{tag}%")
                .where.not(id: current_user.id)
                .limit(5)

    render json: users.map { |u|
      {
        id: u.id,
        name: u.name,
        payrail_tag: u.payrail_tag,
        email: u.email,
        avatar_color: u.avatar_color
      }
    }
  end
end
