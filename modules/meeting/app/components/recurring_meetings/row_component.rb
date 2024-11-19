# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
#++

module RecurringMeetings
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    def column_args(column)
      if column == :title
        { style: "grid-column: span 2" }
      else
        super
      end
    end

    def start_time
      if model["state"] == "open" || model["state"] == "closed"
        link_to start_time_title, project_meeting_path(Project.find(model["project_id"]), Meeting.find(model["id"]))
      else
        start_time_title
      end
    end

    def start_time_title
      safe_join([helpers.format_date(model["start_time"]), helpers.format_time(model["start_time"], include_date: false)], " ")
    end

    def relative_time
      render(OpPrimer::RelativeTimeComponent.new(datetime: model["start_time"], prefix: I18n.t(:label_on)))
    end

    def last_edited
      safe_join([helpers.format_date(model["updated_at"]), helpers.format_time(model["updated_at"], include_date: false)], " ")
    end

    def status
      case model["state"]
      when "open"
        scheme = :success
      when "scheduled"
        scheme = :secondary
      when "cancelled"
        scheme = :severe
      when "closed"
        scheme = :secondary
      end

      render(Primer::Beta::Label.new(scheme:)) do
        render(Primer::Beta::Text.new) { t("label_meeting_state_#{model['state']}") }
      end
    end

    def create
      if model["state"] != "open"
        render(Primer::Beta::Button.new(
                 scheme: :default,
                 size: :medium,
                 tag: :a,
                 href: init_meeting_path(model.recurring_meeting.template, date: model["start_time"])
               )) do |_c|
          I18n.t("label_recurring_meeting_create")
        end
      end
    end

    def button_links
      [
        action_menu
      ]
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": "More",
                              scheme: :invisible,
                              data: {
                                "test-selector": "more-button"
                              })

        if initialized?
          ical_action(menu)

          if delete_allowed?
            delete_action(menu)
          end
        end
      end
    end

    def ical_action(menu)
      menu.with_item(label: I18n.t(:label_icalendar_download),
                     href: download_ics_meeting_path(Meeting.find(model["id"])),
                     content_arguments: {
                       data: { turbo: false }
                     }) do |item|
        item.with_leading_visual_icon(icon: :download)
      end
    end

    def delete_action(menu)
      menu.with_item(label: I18n.t(:label_recurring_meeting_cancel),
                     scheme: :danger,
                     href: meeting_path(Meeting.find(model["id"])),
                     form_arguments: {
                       method: :delete, data: { confirm: I18n.t("text_are_you_sure"), turbo: false }
                     }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def delete_allowed?
      User.current.allowed_in_project?(:delete_meetings, Project.find(model["project_id"]))
    end

    def copy_allowed?
      User.current.allowed_in_project?(:create_meetings, Project.find(model["project_id"]))
    end

    def initialized?
      model["id"].present?
    end
  end
end
