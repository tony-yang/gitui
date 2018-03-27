class CommitsController < ApplicationController
  def show
    @repo_name = params[:repo_name]
    @branch = params[:branch] || 'master'
    repo_url_inside_container = repo_url_in_container_mapping(@repo_name)

    @metadata = {}
    @commits = []

    if Dir.exist? repo_url_inside_container
      repo_data = Rugged::Repository.new(repo_url_inside_container)
      unless repo_data.head_unborn?
        @metadata[:local_branches] = repo_data.branches.each_name(:local).sort

        last_commit_sha = nil
        if 'master' != @branch
          last_commit_sha = repo_data.branches[@branch].target_id
        else
          last_commit_sha = repo_data.head.target_id
        end

        commit_walker = Rugged::Walker.new(repo_data)
        commit_walker.push(last_commit_sha)
        commit_walker.each do |commit|
          @commits.push({
            author: commit.author,
            message: commit.message,
            sha: commit.oid,
            time: commit.time
          })
        end
      end
    end
  end

  private
    def repo_url_in_container_mapping(repo_name)
      return "/db/gitui/#{repo_name}.git"
    end
end
