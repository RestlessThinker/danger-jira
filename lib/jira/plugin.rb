module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  Louie Penaflor/danger-jira
  # @tags monday, weekends, time, rattata
  #
  class DangerJira < Plugin
    def check(key: nil, url: nil, emoji: ":link:", fail_on_warning: false)
      throw Error("'key' missing - must supply JIRA issue key") if key.nil?
      throw Error("'url' missing - must supply JIRA installation URL") if url.nil?

      # Support multiple JIRA projects
      # ((WEB|DROID|PM)-[0-9]+)
      keys = key.kind_of?(Array) ? key.join("|") : key
      jira_key_regex_string = "((#{keys})-[0-9]+)"
      regexp = Regexp.new(/#{jira_key_regex_string}/)

      jira_issues = []
      github.pr_title.gsub(regexp) do |match|
        jira_issues << match
      end

      if !jira_issues.empty?
        jira_urls = jira_issues.map { |issue| link(href: ensure_url_ends_with_slash(url), issue: issue) }.join(", ")
        message("#{emoji} #{jira_urls}")
      else
        msg = "Please add the JIRA issue key to the PR title (e.g. KEY-123)"
        if fail_on_warning
          fail(msg)
        else
          warn(msg)
        end
      end
    end

    private

    def ensure_url_ends_with_slash(url)
      return "#{url}/" unless url.end_with?("/")
      return url
    end

    def link(href: nil, issue: nil)
      return "<a href='#{href}#{issue}'>#{issue}</a>"
    end
  end
end
