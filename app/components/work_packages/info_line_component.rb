# frozen_string_literal: true

class WorkPackages::InfoLineComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(work_package:)
    super

    @work_package = work_package
  end
end
