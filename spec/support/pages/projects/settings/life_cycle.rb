# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

require "support/pages/page"

module Pages
  module Projects
    # TODO: Ideally this would be turned into a module but it would require having the other settings pages being split up.
    class Settings
      class LifeCycle < Pages::Page
        attr_accessor :project

        def initialize(project)
          super()

          self.project = project
        end

        def path
          "/projects/#{project.identifier}/settings/life_cycle"
        end

        # Checks if the life cycle elements are listed in the order given and with the correct toggle state.
        # @param life_cycle_elements [Hash{LifeCycleElement => Boolean}]
        def expect_listed(**life_cycle_elements)
          if life_cycle_elements.size > 1
            life_cycle_elements.each_cons(2) do |(predecessor, _), (successor, _)|
              expect(page).to have_css("#{life_cycle_test_selector(predecessor)} + #{life_cycle_test_selector(successor)}")
            end
          end

          life_cycle_elements.each do |element, active|
            expect_toggle_state(element, active)
          end
        end

        def expect_toggle_state(element, active)
          within toggle_element(element) do
            expect(page)
              .to have_css(".ToggleSwitch-status#{expected_toggle_status(active)}"),
                  "Expected toggle for '#{element.name}' to be #{expected_toggle_status(active)} " \
                  "but was #{expected_toggle_status(!active)}"
          end
        end

        def toggle(element)
          toggle_element(element).click
        end

        def life_cycle_test_selector(element)
          test_selector("project-life-cycle-element-#{element.id}")
        end

        def toggle_element(element)
          find_test_selector("toggle-project-life-cycle-#{element.id}")
        end

        def expected_toggle_status(active)
          active ? "On" : "Off"
        end
      end
    end
  end
end
