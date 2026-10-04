# frozen_string_literal: true

# UserPresenter (Demonstrating Q73 - Presenter / Decorator Pattern)
#
# Key Architectural Features:
# 1. Presentation Separation: Wraps a model to format data for UI/views without polluting the domain model.
# 2. Instance Testability: Unlike global Rails helpers, presenters are plain objects easily unit-tested.
# 3. Strict Rule: Holds display logic only (HTML badges, avatar initials, formatted tags), NEVER business rules.
class UserPresenter
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def display_name
    user.name.titleize
  end

  def formatted_tag
    user.payrail_tag.presence || "$anonymous"
  end

  def initials
    user.name.split.map(&:first).join.upcase[0..1]
  end

  def verification_badge
    if user.kyc_verified?
      %(<span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800">Verified</span>)
    else
      %(<span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-amber-100 text-amber-800">Pending KYC</span>)
    end
  end

  def role_badge_color
    case user.role
    when "admin" then "bg-purple-100 text-purple-800"
    when "merchant" then "bg-blue-100 text-blue-800"
    else "bg-slate-100 text-slate-800"
    end
  end

  # Delegates unknown methods cleanly to underlying user
  def method_missing(method_name, *args, &block)
    if user.respond_to?(method_name)
      user.public_send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    user.respond_to?(method_name, include_private) || super
  end
end
