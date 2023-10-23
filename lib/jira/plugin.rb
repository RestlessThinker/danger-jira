module Danger
  # Links JIRA issues to a pull request.
  #
  # @example Check PR for the following JIRA project keys and links them
  #
  #          jira.check(key: "KEY", url: "https://myjira.atlassian.net/browse")
  #
  # @see  RestlessThinker/danger-jira
  # @tags jira
  #
  class DangerJira < Plugin
    # Checks PR for JIRA keys and links them
    #
    # @param [Array] key
    #         An array of JIRA project keys KEY-123, JIRA-125 etc.
    #
    # @param [String] url
    #         The JIRA url hosted instance.
    #
    # @param [String] emoji
    #         The emoji you want to display in the message.
    #
    # @param [Boolean] search_title
    #         Option to search JIRA issues from PR title
    #
    # @param [Boolean] search_commits
    #         Option to search JIRA issues from commit messages
    #
    # @param [Boolean] search_branch
    #         Option to search JIRA issues from the name of the PR branch
    #
    # @param [Boolean] fail_on_warning
    #         Option to fail danger if no JIRA issue found
    #
    # @param [Boolean] report_missing
    #         Option to report if no JIRA issue was found
    #
    # @param [Boolean] skippable
    #         Option to skip the report if 'no-jira' is provided on the PR title, description or commits. 'nojira' is also allowed on branch names.
    #
    # @return [void]
    #
    def check(key: nil, url: nil, emoji: ":link:", search_title: true, search_commits: false, search_branch: false, search_body: false, fail_on_warning: false, report_missing: true, skippable: true)
      throw Error("'key' missing - must supply JIRA issue key") if key.nil?
      throw Error("'url' missing - must supply JIRA installation URL") if url.nil?

      return if skippable && should_skip_jira?(search_title: search_title)

      jira_issues = find_jira_issues(
        key: key,
        search_title: search_title,
        search_commits: search_commits,
        search_branch: search_branch,
        search_body: search_body
      )

      if !jira_issues.empty?
        jira_urls = jira_issues.map { |issue| link(href: ensure_url_ends_with_slash(url), issue: issue) }.join(", ")
        message("#{emoji} #{jira_urls}")
      elsif report_missing
       msg = error_message_for(
          search_title,
          search_commits,
          search_branch,
          search_body
        )
        if fail_on_warning
          fail(msg)
        else
          warn(msg)
        end
      end
    end

    private

    def vcs_host
      return gitlab if defined? @dangerfile.gitlab
      return github
    end

    def error_message_for(search_title, search_commits, search_branch, search_body)
      error_string = ""
      error_string += ", title" if search_title
      error_string += ", commit messages" if search_commits
      error_string += ", branch name" if search_branch
      error_string += ", body" if search_body
      return "This PR does not contain any JIRA issue keys in the PR" + error_string[1..-1] + " (e.g. KEY-123)"
    end

    def find_jira_issues(key: nil, search_title: true, search_commits: false, search_branch: false, search_body: false)
      # Support multiple JIRA projects
      keys = key.kind_of?(Array) ? key.join("|") : key
      jira_key_regex_string = "((?:#{keys})-[0-9]+)"
      regexp = Regexp.new(/#{jira_key_regex_string}/)

      jira_issues = []

      if search_title
        vcs_host.pr_title.gsub(regexp) do |match|
          jira_issues << match
        end
      end

      if search_commits
        git.commits.map do |commit|
          commit.message.gsub(regexp) do |match|
            jira_issues << match
          end
        end
      end

      if search_branch
        vcs_host.branch_for_head.gsub(regexp) do |match|
          jira_issues << match
        end
      end

      if search_body
        vcs_host.pr_body.gsub(regexp) do |match|
          jira_issues << match
        end
      end
      return jira_issues.uniq
    end

    def should_skip_jira?(search_title: true)
      # Consider first occurrence of 'no-jira' or nojira
      regexp = Regexp.new("(no-jira|nojira)", true)

      if search_title
        vcs_host.pr_title.gsub(regexp) do |match|
          return true unless match.empty?
        end
      end

      vcs_host.pr_body.gsub(regexp) do |match|
        return true unless match.empty?
      end

      vcs_host.branch_for_head.gsub(regexp) do |match|
        return true unless match.empty?
      end

      return false
    end

    def ensure_url_ends_with_slash(url)
      return "#{url}/" unless url.end_with?("/")
      return url
    end

    def link(href: nil, issue: nil)
      return "<a href='#{href}#{issue}'>#{issue}</a>"
    end
  end
end
