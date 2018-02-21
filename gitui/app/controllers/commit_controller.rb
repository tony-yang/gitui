class CommitController < ApplicationController
  def show
    @repo_name = params[:repo_name]
    sha_path = params[:sha]

    repo_url_inside_container = repo_url_in_container_mapping(@repo_name)

    @commit_metadata = {}
    @diff_content = []

    if Dir.exist? repo_url_inside_container
      repo_data = Rugged::Repository.new(repo_url_inside_container)
      if repo_data and not repo_data.head_unborn?
        if /(?<selected_sha_one>\h+)\.{2,}(?<selected_sha_two>\h+)/ =~ sha_path
          begin
            selected_sha_one_commit = repo_data.lookup(selected_sha_one)
            selected_sha_two_commit = repo_data.lookup(selected_sha_two)
            @commit_metadata = generate_commit_metadata(selected_sha_two_commit)
            @diff_content = generate_diff_content(selected_sha_one_commit, selected_sha_two_commit)
          rescue
            redirect_to repo_commit_path(@repo_name, 'master')
          end
        elsif /(?<selected_sha>\h+)/ =~ sha_path
          begin
            selected_sha_commit = repo_data.lookup(selected_sha)
            previous_commit = nil
            if selected_sha_commit.parents.empty?
              previous_commit = repo_data.lookup('4b825dc642cb6eb9a060e54bf8d69288fbee4904')
            else
              previous_commit = selected_sha_commit.parents[0]
            end
            @commit_metadata = generate_commit_metadata(selected_sha_commit)
            @diff_content = generate_diff_content(previous_commit, selected_sha_commit)
          rescue
            redirect_to repo_commit_path(@repo_name, 'master')
          end
        else
          begin
            last_commit_sha = repo_data.head.target_id
            last_commit = repo_data.lookup(last_commit_sha)
            previous_commit = nil
            if last_commit.parents.empty?
              previous_commit = repo_data.lookup('4b825dc642cb6eb9a060e54bf8d69288fbee4904')
            else
              previous_commit = last_commit.parents[0]
            end
            @commit_metadata = generate_commit_metadata(last_commit)
            @diff_content = generate_diff_content(previous_commit, last_commit)
          rescue
            redirect_to repo_commit_path(@repo_name, 'master')
          end
        end
      end
    end
  end

  private
    def repo_url_in_container_mapping(repo_name)
      return "/db/gitui/#{repo_name}.git"
    end

    def generate_commit_metadata(commit)
      commit_metadata = {}
      commit_metadata[:author] = commit.author
      commit_metadata[:message] = commit.message
      commit_metadata[:parent_ids] = commit.parent_oids
      commit_metadata[:sha] = commit.oid
      commit_metadata[:time] = commit.time
      return commit_metadata
    end

    def generate_diff_content(selected_sha_one_commit, selected_sha_two_commit)
      diff_content = []
      diff_commits = selected_sha_one_commit.diff(selected_sha_two_commit)
      diff_commits.each do |d|
        diff_content.push ({
          changes: d.changes,
          additions: d.additions,
          deletions: d.deletions,
          old_file: d.delta.old_file[:path],
          new_file: d.delta.new_file[:path],
          diff: diff_patch_to_parallel_view(d.to_s)
        })
      end
      return diff_content
    end

    def diff_patch_to_parallel_view(diff_patch)
      diff_in_parallel = {old: [], new: []}
      line_num_in_old = 1
      line_num_in_new = 1
      diff = diff_patch.split("\n")
      diff.each_index do |index|
        # Skip the header section of the diff patch
        if index > 3
          if /^-/ =~ diff[index]
            diff_in_parallel[:old].push({
              line: diff[index],
              line_num: line_num_in_old,
              line_type: 'delete-line'
            })
            line_num_in_old += 1
          elsif /^\+/ =~ diff[index]
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
            if /^@/ =~ diff[index]
              diff_in_parallel[:old].push({
                line: diff[index], line_num: '', line_type: ''
              })
              diff_in_parallel[:new].push({
                line: diff[index], line_num: '', line_type: ''
              })
            elsif /^\\ No newline at end of file/ =~ diff[index]
              next
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

      return diff_in_parallel
    end
end
