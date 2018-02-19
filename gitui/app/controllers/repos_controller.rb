class ReposController < ApplicationController
  def index

  end

  def show
    @repo = Repo.find(params[:id])
  end

  def new
  end

  def create
    @repo = Repo.new(repo_params)
    @repo['url'] = "/Users/tony/db/gitui/#{@repo['name']}.git"
    @repo['owner'] = 'tony-yang'
    repo_url_inside_container = repo_url_in_container_mapping(@repo['name'])

    if not File.exist?(repo_url_inside_container)
      # We are assuming the gitui dir always exists
      # and the directory we are creating is only 1 level deep
      Dir.mkdir repo_url_inside_container
      Rugged::Repository.init_at(repo_url_inside_container, :bare)
      if params[:repo][:readme] == 1.to_s
        commit_and_push_first_readme(repo_url_inside_container, @repo['url'], @repo['owner'])
      end
      @repo.save
    end
    redirect_to @repo
  end

  private
    def repo_params
      params.require(:repo).permit(:name)
    end

    def repo_url_in_container_mapping(repo_name)
      return "/db/gitui/#{repo_name}.git"
    end

    def commit_and_push_first_readme(repo_url, repo_name, repo_owner)
      repo = Rugged::Repository.new(repo_url)

      oid = repo.write("\# #{repo_name}", :blob)
      index = repo.index
      index.add(:path => 'README.md', :oid => oid, :mode => 0100644)

      options = {}
      options[:tree] = index.write_tree(repo)
      options[:author] = {
        :email => 'test@email.com',
        :name => repo_owner,
        :time => Time.now
      }
      options[:committer] = options[:author]
      options[:message] ||= 'Initial commit'
      options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
      options[:update_ref] = 'HEAD'
      Rugged::Commit.create(repo, options)
    end
end
