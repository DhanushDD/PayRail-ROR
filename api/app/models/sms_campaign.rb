# frozen_string_literal: true

# SmsCampaign Model (Demonstrating Q150 - Large SMS Campaign System)
#
# Key Architectural Features:
# 1. Explicit Lifecycle States: 'draft', 'running', 'paused', 'completed'.
# 2. Safe Pause/Resume: Workers verify status before each batch to halt gracefully without thread starvation.
# 3. Batch Dispatching: Processes recipients using `in_batches` or `find_each` to preserve flat memory.
class SmsCampaign < ApplicationRecord
  has_many :sms_recipients, dependent: :destroy

  validates :title, presence: true
  validates :message, presence: true
  validates :status, inclusion: { in: %w[draft running paused completed] }

  def running?
    status == "running"
  end

  def paused?
    status == "paused"
  end

  def pause!
    update!(status: "paused")
  end

  def resume!
    update!(status: "running")
  end

  def complete!
    update!(status: "completed")
  end
end
