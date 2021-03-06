require 'date'
require 'ostruct'

module SmartAnswer::Calculators
  class HolidayEntitlement < OpenStruct
    # created for the holiday entitlement calculator

    def full_time_part_time_days
      days = (5.6 * fraction_of_year * days_per_week).round(10)
      days > days_cap ? days_cap : days
    end

    def full_time_part_time_hours
      (5.6 * fraction_of_year * hours_per_week).round(10)
    end

    def full_time_part_time_hours_and_minutes
      (full_time_part_time_hours * 60).floor.divmod(60).map(&:floor)
    end

    def casual_irregular_entitlement
      minutes = (5.6 / 46.4 * total_hours * 60).round(10)
      minutes.floor.divmod(60).map(&:floor)
    end

    def annualised_hours_per_week
      (total_hours / 46.4).round(10)
    end

    def annualised_entitlement
      # These are the same at the moment
      casual_irregular_entitlement
    end

    def compressed_hours_entitlement
      minutes = (5.6 * hours_per_week * 60).round(10)
      minutes.floor.divmod(60).map(&:floor)
    end

    def compressed_hours_daily_average
      minutes = (hours_per_week / days_per_week * 60).round(10)
      minutes.floor.divmod(60).map(&:floor)
    end

    def shift_entitlement
      (5.6 * fraction_of_year * shifts_per_week).round(10)
    end

    def fraction_of_year
      return 1 if self.start_date.nil? && self.leaving_date.nil?

      days_divide = leave_year_range.leap? ? 366 : 365

      if start_date && leaving_date
        (leaving_date - start_date + 1) / days_divide
      elsif leaving_date
        (leaving_date - leave_year_range.begins_on + 1) / days_divide
      else
        (leave_year_range.ends_on - start_date + 1) / days_divide
      end
    end

    def formatted_fraction_of_year(dp = 2)
      format_number(fraction_of_year, dp)
    end

    def strip_zeros(number)
      number.to_s.sub(/\.0+$/, '')
    end

    def method_missing(symbol, *args)
      # formatted_foo calls format_number on foo
      formatting_method = formatting_method(symbol)
      if formatting_method
        format_number(send(formatting_method), args.first || 1)
      else
        super
      end
    end

    def respond_to?(symbol, include_all = false)
      formatting_method(symbol).present? || super
    end

  private

    def formatting_method(symbol)
      matches = symbol.to_s.match(/\Aformatted_(.*)\z/)
      matches ? matches[1].to_sym : nil
    end

    def leave_year_range
      leave_year_start = self.leave_year_start_date || "1 January"
      SmartAnswer::YearRange.resetting_on(leave_year_start).including(date_calc)
    end

    def shifts_per_week
      (shifts_per_shift_pattern.to_f / days_per_shift_pattern.to_f * 7).round(10)
    end

    def date_calc
      if self.start_date
        start_date
      else
        leaving_date
      end
    end

    def format_number(number, dp = 1)
      str = sprintf("%.#{dp}f", number)
      strip_zeros(str)
    end

    def days_cap
      (28 * fraction_of_year).round(10)
    end
  end
end
