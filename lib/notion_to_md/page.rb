# frozen_string_literal: true

module NotionToMd
  class Page
    attr_reader :page

    def initialize(page:)
      @page = page
    end

    def title
      page.dig(:properties, :Name, :title).inject('') do |acc, slug|
        acc + slug[:plain_text]
      end
    end

    def cover
      page.dig(:cover, :external, :url)
    end

    def icon
      page.dig(:icon, :emoji)
    end

    def id
      page[:id]
    end

    def created_time
      DateTime.parse(page['created_time'])
    end

    def last_edited_time
      DateTime.parse(page['last_edited_time'])
    end

    def url
      page[:url]
    end

    def archived
      page[:archived]
    end

    def props
      @props ||= custom_props.deep_merge(default_props)
    end

    def custom_props
      @custom_props ||= page.properties.each_with_object({}) do |prop, memo|
        name = prop.first
        value = prop.last # Notion::Messages::Message
        type = value.type

        next memo unless CustomProperty.respond_to?(type.to_sym)

        memo[name.parameterize.underscore] = CustomProperty.send(type, value)
      end.reject { |_k, v| v.presence.nil? }
    end

    def default_props
      @default_props ||= {
        'id' => id,
        'title' => title,
        'created_time' => created_time,
        'cover' => cover,
        'icon' => icon,
        'last_edited_time' => last_edited_time,
        'archived' => archived
      }
    end

    class CustomProperty
      class << self
        def multi_select(prop)
          multi_select = prop.multi_select.map(&:name).join(', ')
          "[#{multi_select}]"
        end

        def select(prop)
          prop['select'].name
        end

        def people(prop)
          people = prop.people.map(&:name).join(', ')
          "[#{people}]"
        end

        def files(prop)
          files = prop.files.map { |f| "\"#{f.file.url}\"" }.join(', ')
          "[#{files}]"
        end

        def phone_number(prop)
          prop.phone_number
        end

        def number(prop)
          prop.number
        end

        def email(prop)
          prop.email
        end

        def checkbox(prop)
          prop.checkbox.to_s
        end

        # date type properties not supported:
        # - end
        # - time_zone
        def date(prop)
          prop.date.start
        end

        def url(prop)
          prop.url
        end
      end
    end
  end
end