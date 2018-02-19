require 'test_helper'

class ReposControllerTest < ActionDispatch::IntegrationTest
  setup do
    @new_repo_name = 'testrepo1'
    @repo_inside_container_url = "/db/gitui/#{@new_repo_name}.git"
  end

  teardown do
    if Dir.exist? @repo_inside_container_url
      FileUtils.rm_r @repo_inside_container_url
      Repo.find(@new_repo_name).destroy
    end
  end

  test 'should get index' do
    get repos_url
    assert_response :success
  end

  test 'should create a new repo when the repo name is unique' do
    assert_difference('Repo.count') do
      post repos_url, params: { repo: {
        name: @new_repo_name,
        readme: '1'
      }}
    end
    assert(Dir.exist?(@repo_inside_container_url), 'Failed to create a new repo')
    assert_redirected_to repo_path((Repo.last))
  end

  test 'should not create a new repo when the repo name is not unique' do
    post repos_url, params: { repo: {
      name: @new_repo_name,
      readme: '1'
    }}

    assert_no_difference('Repo.count') do
      post repos_url, params: { repo: {
        name: @new_repo_name,
        readme: '1'
      }}
    end
  end
end
