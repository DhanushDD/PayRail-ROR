class RegistrationsController < ApplicationController
  def new
    redirect_to dashboard_path if logged_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      wallet = @user.wallets.create!(currency: "USD", balance_cents: 100000)

      transfer = Transfer.create!(
        recipient_wallet: wallet,
        amount_cents: 100000,
        fee_cents: 0,
        currency: "USD",
        transfer_type: "deposit",
        status: "completed",
        category: "deposit",
        description: "PayRail New Member Bonus Funding"
      )

      LedgerEntry.create!(
        transfer: transfer,
        wallet: wallet,
        entry_type: "credit",
        amount_cents: 100000,
        balance_after_cents: 100000,
        description: "Welcome Bonus Credit"
      )

      @user.virtual_cards.create!(
        wallet: wallet,
        cardholder_name: @user.name.upcase,
        brand: "Visa",
        tier: "Black Metal"
      )

      session[:user_id] = @user.id
      flash[:notice] = "Welcome to PayRail! Your account has been funded with $1,000.00 demo credit."
      redirect_to dashboard_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :payrail_tag, :password, :password_confirmation, :phone_number)
  end
end
