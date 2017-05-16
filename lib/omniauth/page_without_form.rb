# frozen_string_literal: true

# Variation of form page that doesn't have a form.
module OmniAuth
  class PageWithoutForm < OmniAuth::Form
    def self.build(options = {}, &block)
      form = OmniAuth::PageWithoutForm.new(options)
      if block.arity > 0
        yield form
      else
        form.instance_eval(&block)
      end
      form
    end

    def header(title, header_info)
      @html << <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <title>#{title}</title>
        #{css}
        #{header_info}
      </head>
      <body>
      HTML
      self
    end

    def footer
      return self if @footer
      @html << <<-HTML
      </body>
      </html>
      HTML
      @footer = true
      self
    end
  end
end
