class CommitController < ApplicationController
  def show
    repo_name = params[:repo_name]
    repo_url_inside_container = repo_url_in_container_mapping(repo_name)

    @commit_metadata = {}
    @diff_content = []

    if Dir.exist? repo_url_inside_container
      repo_data = Rugged::Repository.new(repo_url_inside_container)
      unless repo_data.head_unborn?
        last_commit_sha = repo_data.head.target_id
        commit = repo_data.lookup(last_commit_sha)
        @commit_metadata[:author] = commit.author
        @commit_metadata[:message] = commit.message
        @commit_metadata[:parent_ids] = commit.parent_oids
        @commit_metadata[:sha] = commit.oid
        @commit_metadata[:time] = commit.time

        diff_commits = commit.parents[0].diff(commit)
        diff_commits.each do |d|
          current_diff = {}
          current_diff[:changes] = d.changes
          current_diff[:additions] = d.additions
          current_diff[:deletions] = d.deletions
          current_diff[:old_file] = d.delta.old_file[:path]
          current_diff[:new_file] = d.delta.new_file[:path]
          current_diff[:diff] = diff_patch_to_parallel_view(d.to_s)
          @diff_content.push current_diff
        end
      end
    end
  end

  private
    def repo_url_in_container_mapping(repo_name)
      return "/db/gitui/#{repo_name}.git"
    end

    def diff_patch_to_parallel_view(diff_patch)
      diff_in_parallel = {old: [], new: []}
      line_num_in_old = 1
      line_num_in_new = 1
      diff = diff_patch.split("\n")
      diff.each_index do |index|
        # Skip the header section of the diff patch
        if index > 3
          if diff[index] =~ /^-/
            diff_in_parallel[:old].push({
              line: diff[index],
              line_num: line_num_in_old,
              line_type: 'delete-line'
            })
            line_num_in_old += 1
          elsif diff[index] =~ /^\+/
            diff_in_parallel[:new].push({
              line: diff[index],
              line_num: line_num_in_new,
              line_type: 'add-line'
            })
            line_num_in_new += 1
          else
            num_of_line_in_old = diff_in_parallel[:old].size
            num_of_line_in_new = diff_in_parallel[:new].size
            if num_of_line_in_old > num_of_line_in_new
              additional_line = Array.new(num_of_line_in_old - num_of_line_in_new) {{
                line: '', line_num: '', line_type: ''
              }}
              diff_in_parallel[:new].concat(additional_line)
            elsif num_of_line_in_old < num_of_line_in_new
              additional_line = Array.new(num_of_line_in_new - num_of_line_in_old) {{
                line: '', line_num: '', line_type: ''
              }}
              diff_in_parallel[:old].concat(additional_line)
            end
            if diff[index] =~ /^@/
              diff_in_parallel[:old].push({
                line: diff[index], line_num: '', line_type: ''
              })
              diff_in_parallel[:new].push({
                line: diff[index], line_num: '', line_type: ''
              })
            else
              diff_in_parallel[:old].push({
                line: diff[index],
                line_num: line_num_in_old,
                line_type: ''
              })
              line_num_in_old += 1
              diff_in_parallel[:new].push({
                line: diff[index],
                line_num: line_num_in_new,
                line_type: ''
              })
              line_num_in_new += 1
            end
          end
        end
      end
      return diff_in_parallel
    end
end
