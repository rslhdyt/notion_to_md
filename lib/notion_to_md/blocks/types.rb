# frozen_string_literal: true

module NotionToMd
  module Blocks
    class Types
      class << self
        def paragraph(block)
          return blank if block[:rich_text].empty?

          convert_text(block)
        end

        def heading_1(block)
          "# #{convert_text(block)}"
        end

        def heading_2(block)
          "## #{convert_text(block)}"
        end

        def heading_3(block)
          "### #{convert_text(block)}"
        end

        def callout(block)
          icon = get_icon(block[:icon])
          text = convert_text(block)
          "> #{icon} #{text}"
        end

        def quote(block)
          "> #{convert_text(block)}"
        end

        def bulleted_list_item(block)
          "- #{convert_text(block)}"
        end

        def numbered_list_item(block, index = nil)
          return bulleted_list_item(block) if index.nil?

          "#{index}. #{convert_text(block)}"
        end

        def to_do(block)
          checked = block[:checked]
          text = convert_text(block)

          "- #{checked ? '[x]' : '[ ]'} #{text}"
        end

        def code(block)
          language = block[:language]
          text = convert_text(block)

          language = 'text' if language == 'plain text'

          "```#{language}\n#{text}\n```"
        end

        def embed(block)
          url = block[:url]

          "[#{url}](#{url})"
        end

        def image(block)
          type = block[:type].to_sym
          url = URI.parse(block.dig(type, :url))
          
          image_md = "![](#{url})" 

          if type == :file
            filename = url.path.split('/')[-2..-1].join('-')
            filename_path = "assets/images/posts/#{filename}"
            
            # download the image if it doesn't exist
            IO.copy_stream(url.open, filename_path) unless File.exist?(filename_path)

            image_md = "![](/#{filename_path})"
          end

          caption = convert_caption(block)
          image_md += "\n<em>#{caption}</em>" unless caption.empty?

          return image_md
        end

        def bookmark(block)
          url = block[:url]
          "[#{url}](#{url})"
        end

        def divider(_block)
          '---'
        end

        def blank
          '<br />'
        end

        def table_row(block)
          "|#{block[:cells].map(&method(:convert_table_row)).join('|')}|"
        end

        def link_preview(block)
          url = block[:url]

          "[#{url}](#{url})\n"
        end

        private

        def convert_table_row(cells)
          cells.map(&method(:convert_table_cell))
        end

        def convert_table_cell(text)
          convert_text({ rich_text: [text] })
        end

        def convert_text(block)
          block[:rich_text].map do |text|
            content = Text.send(text[:type], text)
            enrich_text_content(text, content)
          end.join
        end

        def convert_caption(block)
          convert_text(rich_text: block[:caption])
        end

        def get_icon(block)
          type = block[:type].to_sym
          block[type]
        end

        def enrich_text_content(text, content)
          enriched_content = add_link(text, content)
          add_annotations(text, enriched_content)
        end

        def add_link(text, content)
          href = text[:href]
          return content if href.nil?

          "[#{content}](#{CGI.unescape(href)})"
        end

        def add_annotations(text, content)
          annotations = text[:annotations].select { |_key, value| !!value }
          annotations.keys.inject(content) do |enriched_content, annotation|
            TextAnnotation.send(annotation.to_sym, enriched_content)
          end
        end
      end
    end
  end
end
