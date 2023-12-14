# frozen_string_literal: true

require 'spec_helper'

describe(NotionToMd) do
  describe('#convert') do
    subject(:md) do
      VCR.use_cassette("notion_page") do
        described_class.convert(page_id: '9dc17c9c9d2e469dbbf0f9648f3288d3')
      end
    end

    it 'document does not start with ---' do
      expect(md.split("\n").first).not_to matching(/^---$/)
    end

    it 'heading_1 to #' do
      expect(md).to matching(/^# Heading 1$/)
    end

    it 'heading_2 to ##' do
      expect(md).to matching(/^## Heading 2$/)
    end

    it 'heading_3 to ###' do
      expect(md).to matching(/^### Heading 3$/)
    end

    it 'callout to emoji+text' do
      expect(md).to matching(/^> 💡 Callout/)
    end

    it 'quote to >' do
      expect(md).to matching(/^> Blablabla./)
    end

    it 'code to ```' do
      expect(md).to matching(/^```$/)
    end

    it 'bulleted_list_item to - ' do
      expect(md).to matching(/- item 1\n- item 2\n- item 3/)
    end

    it 'numbered_list_item to - ' do
      expect(md).to matching(/1. item 1\n2. item 2\n3. item 3/)
    end

    it 'to_do checked to - [x]' do
      expect(md).to matching(/^- \[x\]/)
    end

    it 'to_do checked to - [ ]' do
      expect(md).to matching(/^- \[ \]/)
    end

    it 'embed to [url](url)' do
      expect(md).to matching(%r{^\[https?://\S+\]\(https?://\S+\)$})
    end

    it 'image with caption to ![url]\n\n(caption)' do
      expect(md).to matching(%r{^!\[\]\(https?://\S+\)\s\sJohn Rambo having a coffee})
    end

    it 'bookmark to [url](url)' do
      expect(md).to matching(%r{^\[https?://\S+\]\(https?://\S+\)$})
    end

    it 'divider to ---' do
      expect(md).to matching(/^---$/)
    end

    it 'blank to <br />' do
      expect(md).to matching(%r{^<br />})
    end

    it 'equation to $$ equ $$' do
      expect(md).to matching(/\$\$ \S+ \$\$/)
    end

    it 'italic to *text*' do
      expect(md).to matching(/^\*italic\*$/)
    end

    it 'bold to **text**' do
      expect(md).to matching(/^\*\*bold\*\*$/)
    end

    it 'strike-trough to ~~text~~' do
      expect(md).to matching(/^~~strike-trough~~$/)
    end

    it 'underline to <u>text</u>' do
      expect(md).to matching(%r{^<u>underline</u>$})
    end

    it 'inline code to `text`' do
      expect(md).to matching(/^`inline-code`$/)
    end

    it 'sets links in markdown' do
      expect(md).to matching(%r{\[Lorem ipsum dolor sit amet\]\(https://google.fr/\)})
      expect(md).to matching(%r{\[Nulla quis neque vel odio\]\(https://git.postgresql.org/gitweb/\?p=postgresql.git;a=blob;f=src/bin/initdb/initdb.c;h=c854221a30602c5a1e5abf73b0942b263859d715;hb=HEAD#l3193\)})
      expect(md).to matching(%r{\[Nulla tempus, massa a cursus porta, risus leo varius urna, euismod tristique ante metus vitae lacus\]\(https://swile.co/\)})
    end

    context('with frontmatter') do
      subject(:md) do
        VCR.use_cassette("notion_page") do
          described_class.convert(page_id: '9dc17c9c9d2e469dbbf0f9648f3288d3', frontmatter: frontmatter)
        end
      end

      let(:frontmatter) { true }

      it 'document starts with ---' do
        expect(md.split("\n").first).to matching(/^---$/)
      end

      it 'sets id in frontmatter' do
        expect(md).to matching(/^id: 9dc17c9c-9d2e-469d-bbf0-f9648f3288d3$/)
      end

      it 'sets created_time in frontmatter' do
        expect(md).to matching(/^created_time: 2022-01-23T12:31:00.000Z$/)
      end

      it 'sets last_edited_time in frontmatter' do
        expect(md).to matching(/^last_edited_time: 2023-12-03T14:27:00.000Z$/)
      end

      it 'sets icon in frontmatter' do
        expect(md).to matching(/^icon: 💥$/)
      end

      it 'sets cover in frontmatter' do
        expect(md).to matching(%r{^cover: https?://www.notion.so/images/page-cover/met_canaletto_1720.jpg$})
      end

      it 'sets title in frontmatter' do
        expect(md).to matching(/^title: "Page 1"$/)
      end

      it 'sets archived in frontmatter' do
        expect(md).to matching(/^archived: false$/)
      end

      it 'sets custom property multi_select type in frontmatter' do
        expect(md).to matching(/^multi_select: \["mselect1", "mselect2", "mselect3"\]$/)
      end

      it 'sets custom property select type in frontmatter' do
        expect(md).to matching(/^select: "select1"$/)
      end

      it 'sets custom property people type in frontmatter' do
        expect(md).to matching(/^person: \["John Rambo"\]$/)
      end

      it 'sets custom property date type in frontmatter' do
        expect(md).to matching(/^date: 2021-12-30 00:00:00 \+\d{4}$/)
      end

      it 'sets custom property date with time type in frontmatter' do
        expect(md).to matching(/^date_with_time: 2023-12-02 00:00:00 \+\d{4}$/)
      end

      it 'sets custom property number type in frontmatter' do
        expect(md).to matching(/^numbers: 12$/)
      end

      it 'sets custom property files type in frontmatter' do
        expect(md).to matching(%r{^file: \["https://prod-files-secure.s3.us-west-2.amazonaws.com/4783548e-2442-4bf3-bb3d-ed4ddd2dcdf0/23e8b74e-86d1-4b3a-bd9a-dd0415a954e4/me.jpeg.*\]$})
      end

      it 'sets custom property email type in frontmatter' do
        expect(md).to matching(/^email: hola@test.com$/)
      end

      it 'sets custom property checkbox type in frontmatter' do
        expect(md).to matching(/^checkbox: false$/)
      end

      it 'sets custom property rich_text type in frontmatter' do
        expect(md).to matching(/^rich_text: "This is a rich_text property. With Italics."$/)
      end

      it 'does not set empty rich text property in frontmatter' do
        expect(md).not_to matching(/^empty_rich_text: ""$/)
      end

      it 'sets created_by object in frontmatter' do
        expect(md).to matching(/^created_by_object: user$/)
      end

      it 'sets last_edited_by ibject in frontmatter' do
        expect(md).to matching(/^last_edited_by_object: user$/)
      end

      it 'sets created_by id in frontmatter' do
        expect(md).to matching(/^created_by_id: db313571-0280-411f-a6de-70e826421d12$/)
      end

      it 'sets last_edited_by id in frontmatter' do
        expect(md).to matching(/^last_edited_by_id: db313571-0280-411f-a6de-70e826421d12$/)
      end
    end
  end
end
