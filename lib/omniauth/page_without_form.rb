# Uses custom markup and CSS for login form.
# @see https://medium.com/makit/styling-omniauth-forms-using-rails-asset-pipeline-6af352025e53
module OmniAuth
  class PageWithoutForm < OmniAuth::Form

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
