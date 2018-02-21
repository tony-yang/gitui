class ReposController < ApplicationController
  def index
    all_repos = Repo.all.reverse
    @repos = []
    all_repos.each do |repo|
      repo_url_inside_container = repo_url_in_container_mapping(repo[:name])
      current_repo = {}
      if Dir.exist? repo_url_inside_container
        repo.attributes.each {|k, v| current_repo[k.to_sym] = v}
        repo_data = Rugged::Repository.new(repo_url_inside_container)
        unless repo_data.head_unborn?
          last_commit_sha = repo_data.head.target_id
          last_commit = repo_data.lookup(last_commit_sha)
          current_repo[:last_commit_time] = last_commit.time
          current_repo[:last_commit_message] = last_commit.message
        end
        @repos.push(current_repo)
      end
    end
  end

  def show
    @repo = Repo.find_by(name: params[:name])
    @metadata = {}
    @readme = nil

    repo_url_inside_container = repo_url_in_container_mapping(@repo[:name])
    if Dir.exists? repo_url_inside_container
        repo_data = Rugged::Repository.new(repo_url_inside_container)
        unless repo_data.head_unborn?
          last_commit_sha = repo_data.head.target_id
          last_commit = repo_data.lookup(last_commit_sha)

          # The repo metadata section
          walker = Rugged::Walker.new(repo_data)
          walker.push(last_commit_sha)
          @metadata[:number_of_commits] = walker.count
          walker.reset

          @metadata[:local_branches] = repo_data.branches.each_name(:local).sort

          # The repo-content section
          @tree = repo_data.lookup(last_commit.tree.oid)
          @tree.each_blob do |file|
            if file[:name] == 'README.md'
              @readme = file
              break
            end
          end

          # The repo readme section
          readme_blob = repo_data.lookup(@readme[:oid])
          # ActionViewer simple_format only converts \n\n to <p>
          # Single \n converts to <br> which is considered bad semantic
          @readme_content = readme_blob.content.gsub(/\n/, "\n\n")
        end
    end
  end

  def show_content
    @repo = Repo.find_by(name: params[:name])
    tree_path = params[:tree].split('/')
    current_tree_oid = nil
    current_tree_type = nil
    @metadata = {}
    @blob_content = nil
    @current_tree = nil

    repo_url_inside_container = repo_url_in_container_mapping(@repo[:name])
    if Dir.exists? repo_url_inside_container
        repo_data = Rugged::Repository.new(repo_url_inside_container)
        unless repo_data.head_unborn?
          last_commit_sha = repo_data.head.target_id
          last_commit = repo_data.lookup(last_commit_sha)

          @metadata[:local_branches] = repo_data.branches.each_name(:local).sort

          # The repo-content section
          tree = repo_data.lookup(last_commit.tree.oid)
          tree_path.each do |current_tree_name|
            tree.each do |item|
              if item[:name] == current_tree_name
                current_tree_oid = item[:oid]
                current_tree_type = item[:type]
                break
              end
            end
            tree = repo_data.lookup(current_tree_oid) unless current_tree_oid.nil?
          end

          if current_tree_type == :blob
            blob = repo_data.lookup(current_tree_oid)
            @blob_content = blob.content.gsub(/\n/, "\n\n")
          elsif current_tree_type == :tree
            @current_tree = repo_data.lookup(current_tree_oid)
          end
        end
    end
  end

  def new
  end

  def create
    @repo = Repo.new(repo_params)
    @repo[:url] = "/Users/tony/db/gitui/#{@repo[:name]}.git"
    @repo[:owner] = 'tony-yang'
    repo_url_inside_container = repo_url_in_container_mapping(@repo[:name])

    if not File.exist?(repo_url_inside_container)
      # We are assuming the gitui dir always exists
      # and the directory we are creating is only 1 level deep
      Dir.mkdir repo_url_inside_container
      Rugged::Repository.init_at(repo_url_inside_container, :bare)
      if params[:repo][:readme] == 1.to_s
        commit_and_push_first_readme(repo_url_inside_container, @repo[:name], @repo[:owner])
      end
      @repo.save
      redirect_to action: 'show', name: @repo[:name]
    else
      flash.now[:error] = 'The repository name already exists!'
      render 'new'
    end
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
