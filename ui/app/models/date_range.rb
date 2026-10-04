# frozen_string_literal: true

# DateRange Value Object (Demonstrating Q74 from Ruby & Rails Interview Handbook)
#
# Key Characteristics:
# 1. Eliminates primitive obsession by grouping start_date and end_date into a cohesive domain concept.
# 2. Immutable: Frozen on initialization.
# 3. Domain rules: Enforces that start_date <= end_date.
# 4. Provides rich domain methods like `include?`, `overlaps?`, and duration calculations.
class DateRange
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    @start_date = start_date.to_date
    @end_date = end_date.to_date

    if @start_date > @end_date
      raise ArgumentError, "start_date (#{@start_date}) cannot be after end_date (#{@end_date})"
    end

    freeze
  end

  def include?(date)
    d = date.to_date
    d >= start_date && d <= end_date
  end

  def overlaps?(other)
    return false unless other.is_a?(DateRange)
    start_date <= other.end_date && other.start_date <= end_date
  end

  def days
    (end_date - start_date).to_i + 1
  end

  def ==(other)
    other.is_a?(DateRange) &&
      start_date == other.start_date &&
      end_date == other.end_date
  end

  def eql?(other)
    other.instance_of?(DateRange) &&
      start_date == other.start_date &&
      end_date == other.end_date
  end

  def hash
    [start_date, end_date].hash
  end

  def to_s
    "#{start_date}..#{end_date}"
  end
end
