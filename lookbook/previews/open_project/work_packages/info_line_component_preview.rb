# frozen_string_literal: true

module OpenProject::WorkPackages
  # @logical_path OpenProject/WorkPackages
  class InfoLineComponentPreview < ViewComponent::Preview
    def playground
      render(WorkPackages::InfoLineComponent.new(id: WorkPackage.visible.pick(:id)))
    end
  end
end
